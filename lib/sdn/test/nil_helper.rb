class NilClass
    def id
        raise Exception, "nil.id was called, and that is almost always a BUG.  Fix it!"
    end
end
