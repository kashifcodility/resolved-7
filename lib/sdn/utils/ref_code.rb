
module SDN
    module Utils
        module RefCode
            const_def :CHARSET, "0123456789abcdefghijklmnopqrstuvwxyz".split("")

            extend self

            def generate(length = 8)
                1.upto(length).map { |_| CHARSET.sample }.join
            end
        end
    end
end
