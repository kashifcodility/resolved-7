module SDN
    module Mixins

        BASE = File.dirname(__FILE__)

        autoload :RetrySave,    BASE + '/mixins/retry_save'
        autoload :Pagination,   BASE + '/mixins/pagination'
        autoload :Paginator,    BASE + '/mixins/paginator'

    end
end
