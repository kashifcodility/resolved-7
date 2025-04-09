#
# Pagination Mixin - uber simple pagination for DM models
#
#   Basically incorporates :limit, :offset (from :page, :count) into
#   any query params passed in.
#
module SDN::Mixins::Paginator

    def self.included(base)
        base.extend(ClassMethods)
    end

    module ClassMethods
        class PaginatedProxy
            include Enumerable

            def each(&block)
                raise ArgumentError, ":count option must be provided." unless @options.has_key?(:count)
                page = 1
                per_page = @options[:count]
                total = 0
                begin
                    count = @options[:limit] ? [@options[:limit]-(total), per_page].min : per_page
                    page_data = paginate(@options.merge(:page=>page, :count=>count))
                    page_data.each(&block)
                    total += page_data.size
                    page  += 1
                    break if @options[:limit] and total >= @options[:limit]
                end until page_data.empty?
            end

            protected

            def initialize(target, options)
                @target = target
                @options = options.dup
                if target.respond_to?(:query) and target.query.options.has_key?(:limit)
                    @options[:limit] = target.query.options[:limit]
                end
            end

            def method_missing(method_id, *args, &block)
                @target.__send__(method_id, *args, &block)
            end

        end

        def batches_of(count, &block)
            enumerator = PaginatedProxy.new(self, :count => count)
            if block_given?
                enumerator.each(&block)
            else
                enumerator
            end
        end

        def paginate(opts)
            return [] unless opts.is_a?(Hash)
            opts[:limit]  = opts.delete(:count) || opts.delete(:limit) || 50
            opts[:offset] = ((opts.delete(:page) || 1) - 1) * opts[:limit]
            return self.all(opts)
        end

    end

end # SDN::Mixins::Paginator
