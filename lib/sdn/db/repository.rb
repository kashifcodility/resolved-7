module SDN
    class DB

        # Repository Class and namespaced subclasses encapsulate
        # adapter-specific behavior around setup/unsetup and
        # materialize/dematerialize for supported repositories.
        class Repository
            include Exceptions

            attr_reader :db      # back-reference to $DB
            attr_reader :name
            attr_reader :config
            attr_reader :logging

            def self.for(string)
                name = string.camelize
                klass = constants.find { |c| c.to_s == name }
                return const_get(klass) if klass
                raise InvalidConfig, "unsupported adapter #{string.inspect}"
            end

            def initialize(opts={})
                @config, @db, @name = opts.values_at(:config, :db, :name)
                self.logging = !!self.config[:logging]
            end

            # noop methods.  override in your subclass
            def dematerialize ; end
            def materialize   ; end
            def setup         ; end
            def unsetup       ; end
            def logging=(*)   ; end
            def cmdline(*)    ; end

            private

            def search_path_for(*names)
                found = names.flatten.find do |name|
                    name = `which #{name}`.chomp
                    name.present?
                end

                raise UtilityNotFound, "unable to find #{names * ' '}" unless found

                return found
            end

            class DataMapper < Repository
                protected

                def normalize_config(hash)
                    return hash.inject({}) do |h, (k,v)|
                        if k == :port
                            h[k] = v.to_i
                        elsif k == :adapter && v == 'postgresql'
                            h[k] = 'postgres'
                        elsif v.is_a?(Hash)
                            h[k] = normalize_config(v)
                        else
                            h[k] = v
                        end
                        h
                    end
                end
            end

            class Mysql < DataMapper
                def setup
                    ::DataMapper::setup(name.to_sym, normalize_config(config.except(:logging)))
                    return self
                end

                def unsetup
                    # The key that ties DM and DO together is the normalized_uri
                    # (DataObjects::URI).  We get the normalized_uri's for the
                    # repos in question, then find them in DO's Connection
                    # Pools.
                    repo_uri = ::DataMapper.repository(name).adapter.send(:normalized_uri)

                    # FIXME: Untested.  Not important in the initial release though.
                    ::DataObjects::Pooling.lock.synchronize do
                        ::DataObjects::Pooling.pools.each do |pool|
                            pool.lock.synchronize do
                                conns = pool.available + pool.used.values
                                conns.each do |conn|
                                    conn_uri = conn.instance_variable_get(:@uri)
                                    next unless conn_uri == repo_uri

                                    conn.dispose
                                end
                            end

                            pool.flush!
                        end
                    end
                end

                def materialize
                    db.lock("#{name}_materializing", 600) do
                        cmd = self.cmdline([:username, :password, :host, :port],
                            " -e 'CREATE DATABASE IF NOT EXISTS #{config[:database]}'")
                        `#{cmd}`

                        ::DataMapper.auto_upgrade!(name)
                    end
                end

                def dematerialize
                    db.lock("#{name}_dematerializing", 600) do
                        cmd = self.cmdline([:username, :password, :host, :port],
                            "-e 'DROP DATABASE IF EXISTS #{config[:database]}'")
                        `#{cmd}`
                    end
                end

                def logging=(state)
                    return if @logging == state
                    @logging = state
                    ::DataObjects::Mysql.logger = case state
                        when true  then ::DataMapper.logger = $LOG
                        when false then ::DataMapper::Logger.new(StringIO.new, :fatal)
                        else raise InvalidArgument, "unknown logging state #{state.inspect}"
                    end
                end

                # config keys + concatenated string
                def cmdline(keys = [:username, :password, :host, :database, :port], string = nil)
                    @utility ||= search_path_for("mysql", "mysql5")

                    cmd = [ @utility ]
                    self.config.only(*keys).each do |k, v|
                        cmd << case k
                            when :username then "--user='#{v}'"
                            when :password then v.blank? ? "" : "--password='#{v}'"
                            when :port     then "--port='#{v}'" unless v.blank?
                            when :host     then "--host='#{v}'" unless
                                v.blank? or v.among?("localhost")
                        end
                    end

                    cmd << string if string

                    return cmd.compact * ' '
                end
            end

            class Salesforce < DataMapper
                def logging=(state)
                    return if @logging == state
                    @logging = state

                    adapters = ::DataMapper::Repository.adapters.values.
                        select { |a| a.kind_of? SalesforceAdapter }.each do |adapter|

                        adapter.connection.send(:driver).wiredump_dev = state == true ? $LOG : nil
                    end
                end

                def setup
                    config_hash = normalize_config(config.except(:logging))

                    # we never want salesforce to verify, regardless of what our
                    # illustrious config says.
                    config_hash[:verify] = false

                    ::DataMapper.setup(name.to_sym, normalize_config(config.except(:logging)))

                    return self
                end
            end

            class Mongoid < Repository
                # NOTE: mongoid-2.0.2/lib/mongoid/config/replset_database.rb
                # ReplsetDatabase#configure combines Hash inheritance,
                # method_missing and an inline << operation to basically fuck
                # the resulting hash, hence the .deep_clone.
                def setup
                    mc = ::Mongoid.config
                    # FIXME: mongoid will insist on using configured username password even if the server
                    # Does not require authentication....
                    # Therefore, we excluded :username, :password from configuration for now
                    mcs = normalize_config(config.except(:adapter, :logging, :username, :password))
                    mcs = mcs.deep_clone.merge(:logger => (@logging ? $LOG : nil))
                    mc.from_hash(mcs)

                    mc.autocreate_indexes = false

                    return self
                end

                def configure(conf = {})
                    config.merge!(conf)
                end

                def unsetup
                    # TODO: Right now you can only specify one repo, so if it's
                    # a Mongo repo and we're in a Dev context, it's probably the
                    # master database.  Need to address the multiple database
                    # connection stuff in a future rev.  Good enough for initial
                    # release.

                    m = ::Mongoid
                    m.database.connection.close
                    m.instance_variable_set(:@master, nil)
                    m.instance_variable_set(:@databases, {})
                    m.config.reset # settings.clear
                    return self
                end

                def materialize
                    # In the context of Mongo, materialize means "add indexes",
                    # and/or execute a query on each of the related collections
                    # so that Mongo allocates the db files on disk.  We need
                    # only the top-level models for this.
                    #
                    # TODO: Ensure indexing is done in the background
                    # (model.index_options[:background] == true).  Maybe adjust
                    # default, if it needs it.
                    ::Mongoid::Document.descendants.reject { |m| m.embedded? }.each do |model|
                        if model.index_options.any?
                            model.create_indexes
                        else
                            model.first
                        end
                    end
                end

                def dematerialize
                    ::Mongoid.database.connection.drop_database(config[:database])
                end

                def logging=(state)
                    return if @logging == state
                    @logging = state
                    ::Mongoid.config.logger = case state
                        when true  then $LOG
                        when false then nil
                        else raise InvalidArgument, "unknown logging state #{state.inspect}"
                    end
                end

                def cmdline(keys = [:username, :password, :host, :database, :port], string = nil)
                    @utility ||= search_path_for("mongo")

                    cmd = [ @utility ]
                    self.config.only(*keys).each do |k, v|
                        cmd << case k
                            when :username then "--username='#{v}'"
                            when :password then "--password='#{v}'"
                            when :port     then "--port='#{v}'" unless v.blank?
                            when :host     then "--host='#{v}'" unless
                                v.blank? or v == "localhost"
                            when :hosts    then primay_host = v.first.first; "--host='#{primay_host}'" unless
                                primay_host.blank? or primay_host.among?("localhost", "127.0.0.1")
                        end
                    end

                    cmd << string if string

                    return cmd.compact * ' '
                end

                protected

                def normalize_config(hash)
                    return hash.inject({}) do |h, (k,v)|
                        h.merge(k.to_s => v)
                    end
                end
            end
        end
    end
end
