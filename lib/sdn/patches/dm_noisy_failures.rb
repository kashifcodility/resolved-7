# From: https://philosopherdeveloper.com/posts/unbreaking-datamapper.html
# Imported: 10/29/2019 By: jpr5
#
# Gonna stick with this for a while, see how well it does for us.
#
# WARN: Alters the behavior of setting DataMapper::Model.raise_on_save_failure
#       Meaning: we always raise now.

require 'dm-core'
require 'dm-core/resource'

module ::DataMapper
    module Resource
        #alias_method :save?, :save

        def save_balls
            return if self.save? || self.errors.empty?
            error_message = self.errors.map { |e| "#{self.class}: #{e.join(', ')}" }.join("; ")
            raise SaveFailureError.new(error_message, self)
        end
    end
end
