class SDN::DB
    module Fixtures
        extend self

        def delete_fixtures(model_name)
            unless model_class = fixture_model_map[model_name]
                fail "Unable to locate appropriate model for #{model_name}"
            end

            begin
                model_class.all().destroy
            rescue => e
                $LOG.error "could not destroy all #{model_name} instances"
                raise e
            end
        end

        def load_fixtures(model_name, in_dir, identity)
            unless model_class = fixture_model_map[model_name]
                # Try to find this model directly through reflection
                model_class = find_model_class(in_dir) rescue nil
            end

            fail "Unable to locate appropriate model for #{model_name}" unless model_class

            # Do not attempt to sync non-DM models
            return unless model_class <= ::DataMapper::Resource

            unless identity.kind_of?(Enumerable)
                fail "Identity should be list of properties that make up the id"
            end

            options = {
                :identity => identity.map(&:to_sym),
                :model_name => model_name,
            }

            $LOG.debug "loading fixtures for #{model_name}"

            # TODO:  we need a better way to manage fixed identities, especially in Ez::Product
            # when we have multiple fixtures with overlapping identities, we have a problem
            # this is a stop-gap to allow us to detect these conditions
            identity_stamps = Set.new

            # Work-Around:  process fixtures with explicit IDs first
            [ true, false ].each do |includes_id|

                Dir[in_dir / '*.yml'].each do |file|
                    # No .json support for  DataMapper fixtures; no legacy to
                    # handle.
                    case File.extname(file)
                    when ".yml"
                        yaml = YAML.load_file(file)
                    when ".ccyml"
                        # This script assumes all keys are strings, but the Config
                        # system symbolizes all keys. Make either possible.
                        begin
                            yaml = ::SDN::Config.load(file).to_mash
                        rescue SDN::Config::Exceptions::EmptyConfig
                            # Don't care about empty stuff, probably great for some other environment.
                            next
                        end
                    else
                        raise "Unknown file extension for #{file}"
                        next
                    end

                    next unless (yaml.include?('id') == includes_id)

                    identity_criteria = options[:identity].inject({}){|h,k|h.merge(k=>yaml[k.to_s])}
                    model = model_class.first(identity_criteria)

                    # TODO:  we need a better way to manage fixed identities, especially in Ez::Product
                    # at least we'll see failures in this case
                    identity_stamp = identity_criteria.inspect
                    if identity_stamps.include?(identity_stamp)
                        raise("duplicate identities in #{model_name}: identity = #{identity_stamp}, file = #{file.inspect}, conflicting model = #{model.inspect}")
                    end
                    identity_stamps << identity_stamp

                    begin
                        if model
                            # update! doesn't pass us any dirty bit information.  It also doesn't
                            # update the updated_at timestamp for us.  So, we have to figure out ourselves
                            # if the yaml we just loaded in changed anything underneath and set it manually
                            # if it did.

                            # First we strip out all the values and hashify the old data with only the keys
                            # that we have in the yaml.

                            old_data = model.attributes.stringify_keys

                            # Before stripping keys, we check that 'updated_at' is set for the diff later
                            has_timestamp = old_data['updated_at'] ? true : false

                            old_data.slice!(*yaml.keys)

                            # now we need to normalize types between the two hashes.  The types that we
                            # need to normalize include symbols, BigDecimals and DateTime objects.
                            # There is probably some magic ruby-ism to do this an easier way

                            old_data.each_pair do |k,v|
                                # we have to cast symbols and BigDecimals to strings/floats respectively
                                old_data[k] = v.to_f       if old_data[k].kind_of? BigDecimal
                                yaml.merge!(k => v.to_sym) if old_data[k].kind_of? Symbol
                                old_data[k] = v.to_sym     if yaml[k].kind_of? Symbol

                                # and date/time data is a pain in the ass too
                                if v.kind_of? DateTime
                                    case yaml[k]
                                    when Date, Time, DateTime then # great, that's what we need
                                    when String then yaml.merge!(k => DateTime.parse(yaml[k] + DateTime.now))
                                    else raise "#{k.inspect} is a DateTime, YAML provides a #{yaml[k].class}"
                                    end
                                end
                            end

                            # now we can simply hash compare, and if they are the same we didn't change any data
                            yaml.merge!('updated_at' => DateTime.now) if yaml != old_data and has_timestamp
                            model.update!(yaml)
                        else
                            properties = model_class.properties.map(&:name)

                            yaml.merge!('created_at' => DateTime.now) if !yaml['created_at'] and properties.include?(:created_at)
                            yaml.merge!('updated_at' => DateTime.now) if !yaml['updated_at'] and properties.include?(:updated_at)

                            # MySQL will completely ignore INSERT's that specify an
                            # auto-incrementing (sequenced) PK of '0'.  BUT, it will
                            # honor an UPDATE that does the equivalent.
                            #
                            # However, if you set the :id attribute when you
                            # .create! the model instance, it won't get populated
                            # with the *real* id that MySQL gave it.  So we have to
                            # nuke :id out, such that the #update! will know which
                            # PK to change to 0.
                            zero_id = yaml.delete('id') if yaml['id'].to_i == 0
                            model = model_class.create!(yaml)
                            model.update!(:id => 0) if zero_id
                        end
                    rescue Object => e
                        $LOG.error "failure in #{file.inspect}"
                        raise e
                    end

                    unless model.clean?
                        fail "Unable to update #{model.inspect} #{model.errors.inspect}"
                    end
                end
            end
        end

        def fixture_model_map
            return @fixture_model_map if @fixture_model_map

            # map the split :: name and the model class
            models = DataMapper::Model.descendants
            models = models.map do |model_class|
                [model_class.name.split(/:+/), model_class]
            end

            # This sort will prefer model names in a common namespace over nested
            models = models.sort_by do |segments, model_class|
                -segments.length # `-` in front because we want descending order
            end

            # Map the models into key/value pairs ["snake_case_model", Some::SnakeCaseModel]
            models = models.map do |segments, model_class|
                [segments.last.underscore, model_class]
            end

            @fixture_model_map = Hash[models]
        end

        def find_model_class(in_dir)
            in_dir.gsub!("\\", '/')
            model_parts = in_dir.split("/")
            model_parts.reject! {|p| p.among?(['db', 'fixtures']) }
            cur_class = Object
            model_parts.each do |model_part|
                # TODO: #acronym is not available in ActiveSupport 3.0.4, Therefore we need this hack
                # Remove this hack when we upgrade ActiveSupport
                class_name = (model_part == 'cc' ? 'CC' : model_part.classify)
                begin
                    next_class = cur_class.const_get(class_name)
                rescue Exception # const_get actually raise "LoadError", so we need to use this kind of rescue to handle it
                    next_class = nil
                end
                unless next_class
                    puts "Cannot find class #{class_name} in #{cur_class.name}"
                    return nil
                end
                cur_class = next_class
            end
            return cur_class
        end

        def reload_fixtures
            # Mapping of objects to (non-ID) keys (what to key the fixture off of).
            identities = {
                # avoid IDs if syncing FB fixtures in production
                :relationship         => [ :relatiohship_id ],
                # M:N association
                :foo_association  => [ :A_id, :B_id ],

                # mongodb model, no free integer ID
                :product_node         => [ :code ],
                :schematic            => [ :code ],
                :credential_level_map => [ :code ],
                :test_score_map       => [ :code ],
                :template             => [ :code ],
                :file                 => [ :ref_code ],
                :structured_data      => [ :ref_code ],
            }

            always_rebuild = []

            # Walk directories (including symlinks) for datamapper fixtures.
            # These we only support YAML variants for.
            mysql_fixture_dirs = Dir['db/fixtures/{**/*/**/,}*.yml']
            mysql_fixture_dirs.map { |f| File.dirname(f) }.uniq.each do |in_dir|
                klass_name = File.basename(in_dir).singularize
                delete_fixtures(klass_name) if always_rebuild.include?(klass_name.to_sym)
                load_fixtures(klass_name, in_dir, identities[klass_name.to_sym] || [ :id ])
            end

        end
    end
end
