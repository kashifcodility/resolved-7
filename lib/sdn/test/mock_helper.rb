begin
    require 'rack/test'

rescue LoadError

else

    # quick-fix for the 'mock' method not being available at the world object level

    module MockHelper

        def mock(*args)
            return Spec::Mocks::Mock.new(*args)
        end

    end

end
