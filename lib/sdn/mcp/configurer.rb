# a new take on ruby cross-class configuration

module MCP
    module Configurer
        def eigenclass() (class<<self;self;end) end

        CONFIGS = {}

        class Config < Module
            attr_accessor :arr
            def method_missing(sym, &blk); arr.first[sym] = blk; end
            def []=(sym, blk)
                (arr = self.arr).last[sym] = blk
                define_method sym do
                    frame = Module===self ? self : self.class
                    blk   = arr.inject(nil){ |m, e| m || e[sym] }
                    frame.instance_eval(&blk)
                end
            end
        end

        ::WORLDWIDE = Config.new
        ::WORLDWIDE.arr = [{}]

        def config sym = nil, &blk
            !sym and CONFIGS[self] or CONFIGS[self][sym] = blk
        end

        def config_from klass
            CONFIGS[klass]     ||= Config.new
            CONFIGS[klass].arr ||= [{}]+::WORLDWIDE.arr+[{}]
            [self, eigenclass].each{ |x| x.send :include, CONFIGS[klass] }
        end

        def self.extend_object klass
            super; klass.config_from klass
        end
    end
end
