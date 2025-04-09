require 'active_support/deprecation/proxy_wrappers'

module ::ReAddMissingRequireMethod

    def initialize(*args)
        ActiveSupport::Deprecation::DeprecatedConstantProxy.send(:define_method, :require) { |file| ::Kernel.require(file) }
        super(*args)
    end

end

class ActiveSupport::Deprecation::DeprecatedConstantProxy
    prepend ::ReAddMissingRequireMethod
end
