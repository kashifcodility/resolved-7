# dm-migrations 1.1.0 sends every model the auto_{upgrade,migration} regardless
# of the specified scope.  So we scope it.

module DataMapper
    module Migrations
        module SingletonMethods
            def repository_execute(method, repository_name)
                models = DataMapper::Model.descendants
                models = models.select { |m| m.default_repository_name == repository_name } if repository_name
                models.each do |model|
                    model.send(method, model.default_repository_name)
                end
            end
        end
    end
end
