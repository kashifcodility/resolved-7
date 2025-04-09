module MCP
class Daemon
module State
    module ClassMethods
        def declare_state(*fields)
            fields.compact.map(&:to_s).each do |field|
                define_method("last_" + field)       { get_state_value(field) }
                define_method("last_" + field + "=") { |value| update_state_value(field, value) }
            end
        end
        alias :state :declare_state
    end

    module InstanceMethods
        def get_state(key)
            @state ||= {}.to_mash
            unless @state[key] ||= SystemState.first_or_create({:name => key}, {:name => key, :value => 0})
                $LOG.fatal "unable to create state #{key}"
                sleep 10
                exit -1
            end
            return @state[key]
        end

        def get_state_value(name) return get_state(name).value end
        def update_state_value(name, value)
            state = get_state(name)
            unless state.update(:value => value)
                raise "unable to save state #{name}: #{state.errors.inspect}"
            end
            return state
        end
    end
end
end
end
