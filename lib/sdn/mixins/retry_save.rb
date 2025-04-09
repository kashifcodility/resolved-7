#
# ModelMixin - utility methods we want all relevant models to include.
#
#   Primarily implements a retry-recreation logic for objects with
#   properties that have proc'd defaults, to account for possible
#   like-field collisions.
#
# NOTE: This is auto-included when the refcode property type is used.  You can
# use it directly by requiring 'mixins', and including this module *after*
# ``include DataMapper::Resource''.
#
# NOTE: Now we only catch IntegrityError's.  We get a SQLError if there is
# connection problem, and since we will end up triggering "before save" hooks
# repeatedly, we don't want to trigger on any condition other than field
# collisions.

module SDN::Mixins::RetrySave
    MAX_SAVE_RETRIES = 5

    def regenerate_proc_defaults
        self.send(:properties).select{ |p| p.default.is_a?(Proc) }.each do |prop|
            attribute_set(prop.name, prop.default.call(self, prop))
        end
    end

    def save_self(*args)
        return super unless new?
        retries = 0
        begin
            super
        rescue DataObjects::IntegrityError
            raise if retries == MAX_SAVE_RETRIES

            srand

            regenerate_proc_defaults
            retries += 1
            retry
        end
    end
end
