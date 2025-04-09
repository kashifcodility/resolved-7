class SDN::DB

    # NOTE: Not *entirely* an accurate name - "db logging" is really "db:query
    # logging", but we've gone so long with the semantic that it's too late to
    # change.  This stuff is logging too, but it's a different kind -
    # instantiation logging.  Who the fuck wants to see the word
    # InstantiationLogging, let alone type it.  Seriously!  So fuckit.

    module Logging
        extend self

        def enable!
            return unless Object.const_defined?(:DataMapper)

            ::DataMapper::Model.module_eval    { include Model }
            ::DataMapper::Resource.module_eval { include Resource }
        end

        # Shlepped over from Brendan's old stuff.  Resource requires a different
        # method because of DM's "chainable" mechanism - basically can't call
        # super.

        module Model
            def allocate
                result = super
                $LOG.debug "#{self} allocated"
                result
            end
        end

        module Resource

            def initialize_with_logging(*args)
                result = initialize_without_logging(*args)
                $LOG.debug "#{self.class} initialized"
                result
            end

            def self.included(klass)
                klass.module_eval do
                    unless instance_methods.include?(:initialize_without_logging)
                        alias_method :initialize_without_logging, :initialize
                        alias_method :initialize, :initialize_with_logging
                    end
                end
            end
        end
    end
end
