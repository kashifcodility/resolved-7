module SessionHelper

    def session
        @session ||= {}
    end

    def session_reset
        @session = {}
    end

    # to support our naming standard & a general pattern
    # if it's in the session, returns it
    # otherwise, evaluates the block (if provided) and sessionizes (if non-nil)
    def sessioned_or_new(name, &block)
        model = session[name]
        if model.nil? && block
            model = block.call
            session[name] = model if model
        end
        model
    end

end
