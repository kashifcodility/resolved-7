module SDN
    module Utils
        module Among
            def among?(*args)
                args.flatten.include?(self)
            end
        end
    end
end

::Object.send(:include, ::SDN::Utils::Among)
