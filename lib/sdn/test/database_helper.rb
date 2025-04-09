# Transactional Tests - At last!  We create a transaction for all known
# repositories for each scenario, and roll them back at the end.  This saves us
# from having to delete (possibly) intermediate/cuked data, which is generally
# the most time consuming part of running tests.

module DatabaseHelper
    module Shared
        def models_for(repository, exclude = [])
            repository = repository.to_sym
            return ::DataMapper::Model.descendants.select { |m| m.repository.name == repository } - exclude
        end

        # Loop through repository *names* and construct Repository references
        # based on the names.  Model.repository passes through to
        # DataMapper.repository(default_repository_name), but the consequence of
        # that is Repository instance construction on *every* call.
        def known_repositories(reload=false)
            @known_repositories = nil if reload
            @known_repositories ||= ::DataMapper::Model.descendants.map(&:repository_name).uniq.map do |name|
                DataMapper.repository(name)
            end
            return @known_repositories
        end

        def known_repository_names(reload=false)
            return known_repositories(reload).map { |r| r.name }
        end
    end

    module Framework
        include Shared

        def setup_transactional_test
            return unless Object.const_defined? :DataMapper
            known_repositories.each do |r|
                t = r.transaction
                t.begin
                r.adapter.push_transaction(t)
            end
        end

        def teardown_transactional_test
            return unless Object.const_defined? :DataMapper
            known_repositories.each do |r|
                t = r.adapter.pop_transaction
                t.rollback
            end
        end
    end
end
