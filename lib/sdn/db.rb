##
## SDN Database framework
##
#
# TODO: hunt down all $DB.configure + $DB.load_models -> $DB.setup
# TODO: Add debug logging to important actions (like *materialize)
# TODO: Move brunt of fixture loader mech into here
# TODO: figure out how configure(force) might actually be used (git grep $DB.configure)
# TODO: consider internalizing #lock (hiding it) now that the
#       automation doesn't need to access it directly, and repurpose it for
#       non-model locks in the "parallelization" context.
#

require 'base64'
require 'eigenclass'

require 'do_mysql'
require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-serializer'
require 'dm-aggregates'
require 'dm-ar-finders'
require 'dm-migrations'
require 'dm-transactions'
require 'dm-do-adapter'
require 'dm-mysql-adapter'


##
## Derive DB (singleton) from Module so we can send the instance an include for
## the $DB::ABORT stuff.
##

module SDN
    class DB < Module
        include ::Singleton

        module Exceptions
            class AbortTransaction < StandardError; end
            class Error            < RuntimeError; end
            class LockTimeout      < Error; end
            class InvalidConfig    < Error; end
            class InvalidArgument  < Error; end
            class UtilityNotFound  < Error; end

            const_def :ABORT, AbortTransaction
        end
        include Exceptions

        def repositories
            @repositories ||= {}
        end

        def known_configs
            @known_configs ||= {}
        end

        # Convenience method, since we basically do these two together all the
        # time.
        def setup(from_dir = SDNROOT, repos = :all, force = false)
            configure(from_dir + "/config/database.yml", repos, force)
            load_models(from_dir + '/app/models', true)
            return self
        end

        # NOTE: configure now takes a filename OR config hash
        # NOTE: allows logging at top-level and per-repo level (with override semantics)
        def configure(input = SDNROOT + "/config/database.yml", new_repos = :all, force = false)
            # Support both a Hash and a String.  Default is to support old
            # convention (input is a filename string).
            newconf = input
            newconf = ::SDN::Config.load(newconf) if newconf.kind_of? String
            raise InvalidConfig, "no repositories in #{input.inspect}" if newconf[:repositories].blank?

            # Detect when any new_repos are:
            #   - being re-configured
            #   - not provided
            new_repos     = newconf[:repositories].keys if new_repos == :all
            missing_repos = new_repos - newconf[:repositories].keys
            known_repos   = new_repos & self.repositories.keys
            raise InvalidConfig, "missing configs for #{missing_repos.inspect}" if missing_repos.any?

            # Scan through top-level imperatives before we process new configs.
            # Repositories can override some of these settings.

            baseconf = {}
            newconf.each_pair do |k, v|
                case k
                when :logging then
                    baseconf[k] = !!v

                    if _ = v[:instantiation] rescue nil
                        Logging.enable!
                    end
                end
            end

            # Test if there is any difference between new config and old config
            # We should only re-configure repos that have changed configuration
            # This ensure backwards compatibility
            reconfigure_repos = []
            known_repos.each do |repo|
                if newconf[:repositories][repo] != known_configs[repo]
                    $LOG.info "DB: config for #{repo} changed, reconfiguring"
                    reconfigure_repos << repo
                end
            end

            # Unsetup any repositories we're "re-configuring".
            unsetup(reconfigure_repos) if reconfigure_repos.any?

            # Now configure the specific repos we're given configs for.
            # repository(-adapter)-specific logging imperatives override the
            # overall logging directive, so long as they are actually set
            # (non-nil).
            newconf[:repositories].only(*new_repos).each do |name, conf|
                if configured?(name)
                    $LOG.warn "#{name} already setup, skipping"
                    next
                end

                begin
                    known_configs[name] = conf
                    conf = baseconf.merge(conf)
                    repo = Repository.for(conf[:adapter]).new({
                        :db     => self,
                        :name   => name,
                        :config => conf,
                    })
                    repo.setup

                rescue => e
                    $LOG.error(e) { "couldn't configure #{name.to_s} (#{conf.inspect})" }
                    raise

                else
                    # Successful repository configuration, now accumulate it in
                    # the repository hash.
                    $LOG.info "DB: #{name.to_s} (#{conf.inspect})"
                    repositories[name] = repo
                end
            end

            return self
        end

        # Tears down any repositories which have been setup and removes them from the
        # @repos collection and @config.
        def unsetup(repos)
            configured_repos(repos).each do |name, repo|
                repo.unsetup
                repositories.delete(name)
                known_configs.delete(name)
            end

            return self
        end

        ##
        ## NOTE: No default params for *materialize(); we want those actions to
        ## be deliberate.
        ##

        def rematerialize(repos)
            # Have to lock/semaphore this too, in order to defeat a race, right?
            #
            # FIXME: this presumes MySQL
            lock('rematerializing', 600) do
                dematerialize(repos)
                materialize(repos)
            end

            return self
        end

        def dematerialize(repos)
            configured_repos(repos).each do |name, repo|
                repo.dematerialize
            end
            return self
        end

        # Auto-create the DB and models if they're missing.
        def materialize(repos = :default)
            configured_repos(repos).each do |name, repo|
                repo.materialize
            end
            return self
        end
        alias_method :auto_update, :materialize

        # If you're wondering about the following dirglob insanity, know
        # that it gets multi-depth globbing to follow symlinks.  Don't ask
        # why, just read:
        #
        # http://groups.google.com/group/ruby-talk-google/browse_thread/thread/e319f62f55cdea31
        def load_models(from_dir = SDNROOT + '/app/models', validate = true)
            Dir[from_dir / '{**/*/**/,}*.rb'].each do |model_path|
                begin
                    Kernel::require File.expand_path(model_path)
                rescue Exception => e
                    $LOG.error(e) { "unable to load model #{model_path}" }
                end
            end

            # For now, do nothing with the result; log output is informative enough.
            validate_models if validate

            return self
        end

        # Confirm that model schemas are present in the DB.
        #
        # NOTE: This concept doesn't apply to Mongo, since by design it
        # materializes new collections and documents on the fly.
        def validate_models
            # First nuke out any models that belong to repositories we're not
            # supposed to verify.  (i.e. Salesforce)
            models = ::DataMapper::Model.descendants.reject do |model|
                repositories[model.default_repository_name].config[:verify] == false
            end

            # Then detect if the repo is missing, so we can avoid possible
            # exceptions on repeated storage_exists? calls.  A failed SELECT
            # here will raise an exception and LOG for us.
            missing_repos = models.map(&:default_repository_name).uniq.reject do |repo|
                ::DataMapper.repository(repo).adapter.select("SELECT 1") rescue false
            end

            # FIXME: We're doing something wrong, not triggering finalization of
            # ::DataMapper::Model.  This triggers it in the meantime...
            models.each { |m| m.finalize }

            # Finally, validate the presence of the remaining models on
            # repositories we know exist.
            $LOG.quietly do
                missing = models.reject do |model|
                    repo = model.default_repository_name
                    repo.among?(missing_repos) or ::DataMapper.repository(repo).adapter.storage_exists?(model.storage_name)
                end

                if missing.any?
                    $LOG.warn "DB: missing model#{missing.length > 1 ? "s" : ""}: #{missing * ', '}"
                    $LOG.warn "DB: run `SDN_ENV=#{$CONFIG.env} rake setup:db:update` to materialize them in the DB"
                end
            end

            return self
        end

        ##
        ## Utility Methods
        ##

        # puts $DB.select("select count(*) from users").first
        # puts $DB.select("select first_name from users LIMIT 5").inspect
        def select(query)
            return ::DataMapper.repository(:default).adapter.select(query)
        end

        # puts $DB.execute("insert into ..")
        def execute(query)
            return ::DataMapper.repository(:default).adapter.execute(query)
        end

        # This only ever gets called once - the first time a lock is engaged.
        # This ensures it's not even configured unless needed/used.
        def ensure_locking
            @locking_adapter ||= begin
                db   = :sdn_locks
                repo = repositories[:default]
                cmd  = repo.cmdline([:username, :password, :host],
                    "-e 'CREATE DATABASE IF NOT EXISTS #{db.to_s}'")

                `#{cmd}`

                configure({:repositories => { db => repo.config.merge(:database => db.to_s) }})

                ::DataMapper.repository(db).adapter
            end
        end

        # TODO: Eventually convert this to our concept of a mongo lock.
        #
        # Acquire a global DB lock.  Used by multiple processes that are
        # synchronizing data to DBs.
        def lock(name, timeout)
            raise InvalidArgument, "lock timeout must be a number'." unless timeout.kind_of? Numeric
            raise InvalidArgument, "lock requires a block" unless block_given?

            timeout  = timeout.to_i

            acquired = ensure_locking.select("SELECT GET_LOCK('#{name}', #{timeout})").last.to_i == 1

            raise LockTimeout, "timeout waiting for lock #{name} (#{timeout})" unless acquired

            yield
        ensure
            ensure_locking.execute("SELECT RELEASE_LOCK('#{name}')")
        end

        # Allows you to perform a transaction block without referencing
        # a specific model.  Is convenience method similar to repository(){}
        def transaction(repository_name=repository.name, &block)
            return repository(repository_name).transaction.commit { -> { return block.call }.call }
        end

        # Will tell you if you're inside a transaction block right now.
        def in_transaction?(repository_name=repository.name)
            repository(repository_name).adapter.__send__(:transactions).length > 0
        end

        def logging=(state)
            $DB.repositories.each do |_, repository|
                repository.logging = state
            end
        end

        ##
        ## Support Functionality
        ##

        private

        def configured?(repo)
            return !!self.repositories[repo]
        end

        def configured_repos(repos)
            repos &&= Array(repos)
            raise InvalidArgument unless repos.all? { |r| r.kind_of?(::Symbol) }
            return repos == [:all] ? self.repositories.except(:locks) : self.repositories.only(*repos)
        end

    end # DB
end # SDN


require 'sdn/db/patches'
require 'sdn/db/repository'
require 'sdn/db/property'
require 'sdn/db/logging'
require 'sdn/db/fixtures'


# NOTE: This + inheriting from Module is solely for supporting legacy code
# references to $DB::ABORT.  We'll probably be stuck with the include
# forever. :-/
$DB = ::SDN::DB.instance
$DB.send(:include, ::SDN::DB::Exceptions)
