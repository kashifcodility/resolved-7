module SDN
    module Utils
        module Array
            def map_with_index(&block)
                raise 'block required' unless block

                mapped = []
                self.each_with_index do |item, index|
                    mapped << block.call(item, index)
                end

                return mapped
            end
            alias :collect_with_index :map_with_index

            def literalize
                self.map {|v| (v.respond_to?(:literalize) ? v.literalize : v) }
            end

            # Return an Array where where each value has been symbolized, if supported
            def symbolize
                self.collect {|value| value.respond_to?(:symbolize) ? value.symbolize : value }
            end

            def rand!
                return nil if self.empty?
                return self.delete_at((self.size * ::Kernel.rand).to_i)
            end

            def deep_clone
                map do |x|
                    x.respond_to?(:deep_clone) ? x.deep_clone : (x.respond_to?(:dup) ? (x.dup rescue x) : x)
                end
            end

            # see: active_support/core_ext/array/extract_options
            def extractable_options
                return last if (last.is_a?(Hash) && last.extractable_options?)
                return {}
            end

            def to_mash
                to_hash.with_indifferent_access
            end

            def mean
                return self.reduce(:+) / self.size
            end

            def stddev
                mean    = 0
                meansqr = 0

                self.each do |value|
                   mean    += value
                   meansqr += value*value
                end

                mean    /= self.size
                meansqr /= self.size

                return Math.sqrt(meansqr - mean**2)
            end
        end
    end
end

Array.class_eval do
    include ::SDN::Utils::Array
end
