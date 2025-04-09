# -*- mode: ruby -*-
##
## DB data setup routines.
##

#  require 'active_record/fixtures'
#  fixtures_dir = File.join(Rails.root, '/spec/fixtures') #change '/spec/fixtures' to match your fixtures location
#  Dir.glob(File.join(fixtures_dir,'*.yml')).each do |file|
#  base_name = File.basename(file, '.*')
#  puts "Loading #{base_name}..."
#  ActiveRecord::Fixtures.create_fixtures(fixtures_dir, base_name)
#  end

namespace :setup do
    namespace :db do

        desc "Initialize a new schema with defaults."
        task :fresh => 'setup:env' do
            Rake::Task['setup:db:schema'].invoke
            Rake::Task['setup:db:fixtures'].invoke
        end

        desc "Auto-update all the models (leaves data in place)."
        task :update => 'setup:env' do
            $DB.materialize(:all)
        end

        desc "Reset the schema (DESTROYS EVERYTHING)."
        task :schema => 'setup:env' do
            if $CONFIG.env == :production
                # Prevent accidental DB destruction
                raise "This rake task is destructive! DO NOT RUN ON PRODUCTION !!"
            end

            $DB.repositories.each do |repo_name, repo_setting|
                db_host = repo_setting.config[:host]
                # Only allow wiping local database
                next if db_host == "localhost"
                next if db_host =~ /127\.\d+\.\d+\.\d+/

                raise "This rake task is destructive! Only run it on local database !!"
            end

            $DB.rematerialize(:all)
        end

        desc "Update database entries from db/fixtures/*/*.yml defs"
        task :fixtures => 'setup:env' do
            next unless defined? ::DataMapper
            next unless File.exists?('db/fixtures')

            ::SDN::DB::Fixtures.reload_fixtures
        end

    end
end
