module MCP
    class NamedProc < Proc
        attr_reader :name
        def initialize(&block)
            @name = "No Name"
            super(&block)
        end

        def set_name(new_name)
            @name = new_name
        end
    end
end
