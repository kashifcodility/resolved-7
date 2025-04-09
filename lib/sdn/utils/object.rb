module SDN
    module Utils
        module Object

            # Creates a singleton method on this object which simply
            # returns the value.
            def decorate(name, value)
                singleton_eval { define_method(name) { value } }
            end

            # Returns the eigenclass, metaclass aka singleton class.
            def singleton
                class << self; self end
            end

            def singleton_eval(*args, &block)
                singleton.class_eval(*args, &block)
            end

            protected

            # Just tired of the fact we keep setting constants wrong.  Use this if you want to
            # support simple constant overriding and reloading.
            #
            #     class Thing
            #         const_def :REFCODE_LEN, 8
            #         ...
            #         # as opposed to this:
            #         REFCODE_LEN ||= 8 #WRONG!
            #         REFCODE_LEN = 8 unless defined?(REFCODE_LEN) #WRONG!
            #         REFCODE_LEN = 8 unless const_defined?(:REFCODE_LEN) #CORRECT, BUT LONG!
            #     end
            def const_def(name, value)
                if self.is_a?(Module)
                    self.const_set(name, value) unless self.constants.include?(name)
                else
                    ::Object.class_eval { self.const_def(name, value) unless Object.constants.include?(name) }
                end
            end
        end
    end
end

class Object
    include SDN::Utils::Object
end
