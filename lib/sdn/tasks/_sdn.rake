# -*- mode: ruby -*-
##
## SDN Rakefile functionality for general build, setup and
## development tasks.
##

$:.unshift "."

load File.dirname(__FILE__) + '/init.rake'

##
## Main setup tasks
##

#
# We always want DB tasks available, so load them immediately.
#

load 'db.rake'

#
# Core setup task
#

desc "Runs setup:gems + setup:config + setup:update (NOT destructive)"
task :setup => [ "setup:gems", "setup:config", "setup:update" ]

namespace :setup do

    task :env do
        require 'sdn/framework'
        $LOG.console = true # always log to stdout from rake
    end

    task :reset_gems do
        v = `rbenv version`.split.first
        system("for gem in `gem list --no-versions`; do gem uninstall $gem -aIx; done")
        system("rm -rf ~/.rbenv/versions/#{v}/lib/ruby/gems/2.6.0/bundler/gems/*")
        system("rm -rf /usr/local/rbenv/versions/#{v}/lib/ruby/gems/2.6.0/bundler/gems/*")
        system("gem install bundler:1.17.2")
        system("bundle install")
        system("rbenv rehash")

        exit 1 if $? != 0
    end

    # Here for convenience only.
    task :update   => 'setup:db:update'
    task :fixtures => 'setup:db:fixtures'

    desc "Setup as completely new, with new (default) configs"
    task :new      => 'setup:config:fresh'

    desc "Setup with new .default configs AND wipe/create new (empty) DB (DESTRUCTIVE)"
    task :fresh    => [ 'setup:config:fresh', 'setup:db:fresh' ]

end

task :environment => 'setup:env'


##
## Application Configuration
##

task(:appconfig) { load 'appconfig.rake' }

namespace :setup do

    desc "Deploy for development use (uses .#{WHOAMI} configs, dev hostnames)."
    task :config  => :appconfig
    task :configs => :config

    namespace :config do

        desc "Deploy FRESH application config (wipes old if they exist)"
        task :fresh => :appconfig

        desc "Deploy for production-like staging environment use (uses .staging configs, real hostnames)."
        task :staging => :appconfig

        desc "Deploy for production use (uses .live configs, real hostnames)."
        task :live => :appconfig

    end

end

desc "Setup/link your configs from .defaults (NOT destructive)"
task :config => 'setup:config'


##
## Testing
##

# TODO: needs to be updated for whatever approach we take at SDN

task(:testing) { load 'testing.rake' }

desc "Run all defined tests."
task :test => [ 'test:rspecs', 'test:cukes' ]

namespace :test do
    task :env => :testing # testing.rake extends the :env task

    namespace :db do
        task :fresh     => [ 'test:env', 'test:setup' ]
        task :randomize => 'test:env'
    end

    # Holdover from past convention.
    desc "Run all defined tests, with a freshly initialized test DB"
    task :fresh => [ :env, :setup, 'test' ]

    desc "Setup a freshly initialized test DB"
    task :setup => [ :env, 'setup:db:fresh', 'setup:db:fixtures' ]

    desc "Update DB with models inside test DB"
    task :update => [ :env, 'setup:db:update' ]

    desc "Import fixtures into test DB"
    task :fixtures => [ :env, 'setup:db:fixtures' ]
    task :fixture => [ :env, 'setup:db:fixtures' ]

    desc "Run all RSpec specs."
    task :specs => :rspecs
    task :spec  => :rspecs
    task :rspecs => :env

    desc "Run cucumber specs"
    task :cukes => :env
    task :cuke => :cukes
end


##
## Dev environment utility
##

# TODO: write these again
task(:dev) { load 'dev.rake' }

namespace :dev do
    desc "Dev Only: dump database. MySQL, DataStore"
    task :dump_db => :dev

    desc "Dev Only: Restore database. MySQL, DataStore"
    task :restore_db => :dev
end


##
## Production unicorn controlling
##

namespace :app do
    desc "Production only: boot app in daemonized mode"
    task :start => 'setup:env' do
        pid_file = $CONFIG[:pid_file]
        next if File.exists? pid_file
        env = ENV["SDN_ENV"] || "production"
        system("SDN_ENV=#{env} unicorn -Dc boot/unicorn.rb")
    end

    desc "Production only: stop daemonized app (graceful, QUIT)"
    task :stop => 'setup:env' do
        pid_file = $CONFIG[:pid_file]
        next unless File.exists? pid_file
        pid = `cat #{pid_file}`
        system("kill -QUIT #{pid}")
        FileUtils.rm pid_file
    end

    desc "Production only: stop daemonized app (hard TERM)"
    task :kill => 'setup:env' do
        pid_file = $CONFIG[:pid_file]
        next unless File.exists? pid_file
        pid = `cat #{pid_file}`
        system("kill -KILL #{pid}")
        FileUtils.rm pid_file
    end

    desc "Production only: Restart unicorn (graceful, USR2)"
    task :restart => 'setup:env' do
        pid_file = $CONFIG[:pid_file]
        next unless File.exists? pid_file
        pid = `cat #{pid_file}`
        system("kill -USR2 #{pid}")
    end
end

##
## Load Rails3 tasks if we're in a Rails app directory.
##

begin
    load 'rails.rake'
rescue LoadError
end if File.exists?('config/routes.rb')


##
## Load automation to clear elements of the environment.
##

task(:clear) { load 'clear.rake' }

namespace :clear do
    desc "Clear/reset gems (prep for a fresh bundle install)"
    task :gems => :clear

    if File.exists? 'tmp/cache'
        desc "Clear local on-disk cache"
        task :cache => :cache
    end
end


##
## Tasks to create new apps from skeletonized versions.
##

task(:skeletons) { load 'skeletons.rake' }

namespace :new do
    desc "Create new Rails app in GIT: rake new:rails APPNAME"
    task :rails   => :skeletons do
        Rake::Task['skeleton:rails'].invoke
        exit
    end

    desc "Create new Sinatra app in GIT: rake new:sinatra APPNAME"
    task :sinatra => :skeletons do
        Rake::Task['skeleton:sinatra'].invoke
        exit
    end

    desc "Create new MCP::Daemon app in GIT: rake new:daemon APPNAME"
    task :daemon => :skeletons do
        Rake::Task['skeleton:daemon'].invoke
        exit
    end

end
