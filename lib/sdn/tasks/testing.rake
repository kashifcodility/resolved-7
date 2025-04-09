# -*- mode: ruby -*-
#
# NOTE: WRT in-process running of test subsystems, Cucumber returns true if
# there are failures, Rspec returns true if it succeeded.  In either case, Rake
# needs an exception to raise in order to halt dependency processing.

require 'rspec/core'
require 'rspec/core/runner'

require 'cucumber'
require 'cucumber/rake/task'

# NOTE: For some reason, defining this inside the :test namespace results in
# Rake thinking the task is "not_needed", and doesn't run.  Since we don't
# access this task directly (via "test:.." instead), shrug.

begin
    Cucumber::Rake::Task.new(:features) do |t|
        opts = [ "--format pretty --strict -P" ]

        %w[
            test/support/common/boot_cucumber.rb
            test/support/boot_cucumber.rb
            test/step_definitions
        ].each do |f|
            opts << ["-r", f] if File.exists?(f)
        end

        # Supports {TAG,TAGS}=, NAME=, and {FEATURE,FEATURES,FILE,FILES}=.
        # NAME is a *substring* to "Scenario Name".
        name  = ENV['NAME']
        opts << "-n " + name if name

        # Needs to have ``@'' prefix.  See `cucumber --help` for syntax.
        tags  = ENV['TAGS'] || ENV['TAG']
        opts << "-t " + tags if tags

        # Cucumber will interpret FEATURE itself, but under a specific directory
        # (so nine times out of ten it'll error out).  If you specify
        # FEATURE/etc we handle it for you, so we nil it out.
        filter = ENV['FEATURE'] || ENV['FEATURES'] || ENV['FILE'] || ENV['FILES']
        ENV['FEATURE'] = ENV['FEATURES'] = ENV['FILE'] = ENV['FILES'] = nil
        features = FileList[ 'test/features/{**/*/**/,}*.feature' ].grep(/#{filter}/).sort
        features = ["test/.empty"] if features.empty?
        opts << features.join(" ")

        t.cucumber_opts = opts.join(" ")
        t.fork = false
    end
rescue => e
    $LOG.error(e) { "couldn't load cucumber" }
end


namespace :test do

    task :env do
        ENV['SDN_ENV'] = ENV['RUBY_ENV'] = ENV['RACK_ENV'] = ENV['RAILS_ENV'] = "test"
        ENV["ADAPTER"] ||= "mysql" # for DM

        Rake::Task['setup:env'].invoke
    end

    task :cukes do
        # Hack above, needed because of Cukes Rake Task fuckery.
        Rake::Task["features"].invoke
    end

    task :rspecs do
        opts = [ "-c", "-fdocumentation" ] # color

        %w[
            test/support/common/boot_rspec.rb
            test/support/boot_rspec.rb
        ].each do |f|
            opts << ["-r", f] if File.exists?(f)
        end

        name = ENV['NAME']
        opts << ["-e", name] if name

        filter = ENV['SPEC'] || ENV['SPECS'] || ENV['FILE'] || ENV['FILES']
        ENV['SPEC'] =  ENV['SPECS'] = ENV['FILE'] = ENV['FILES'] = nil
        specs  = FileList[ 'test/rspec/{**/*/**/,}*_spec.rb' ].grep(/#{filter}/).sort
        opts << specs if !specs.empty?

        begin
            code = RSpec::Core::Runner.run(opts.flatten)
            exit 1 unless code == 0 # NOTE: This will prevent any downstream test tasks from running if these fail. Needed for CI.
        rescue => e
            $LOG.error(e)
        end

    end

    namespace :db do

        desc "Randomize DB names by adding nonce on the end of them"
        task :randomize do
            nonce = "_" + rand.to_s[2,6]

            # DataMapper handles MySQL DB
            DataMapper::Repository.adapters.each do |name, adapter|
                # First update our own configuration information
                conf = $DB.repositories[name].config

                old_db_name = conf[:database]
                new_db_name = conf[:database] = old_db_name + nonce

                # Then make sure the DBs are created, and that they are
                # destroyed upon exit.
                cmdline = $DB.repositories[name].cmdline

                # Schedule DROP first, just in case something happens during the
                # next 2 lines.
                at_exit { system("echo \"DROP DATABASE #{new_db_name}\" | " + cmdline) }
                system("echo \"CREATE DATABASE #{new_db_name}\" | " + cmdline)

                # Finally update DM/DO's connection configuration in-place.
                adapter.instance_variable_set(:@normalized_uri, nil)

                new_options = adapter.instance_variable_get(:@options).dup
                new_options["database"] = new_db_name

                adapter.instance_variable_set(:@options, new_options)

                $LOG.info "DB: #{name} randomized (#{old_db_name} -> #{new_db_name})"
            end
        end

    end

end
