

namespace :assets do
    desc "Clobber compiled static assets"
    task :clean => 'rails:assets:clean'

    desc "Compile static assets"
    task :compile => 'rails:assets:compile'

    desc "Recompile static assets"
    task :recompile => 'rails:assets:recompile'
end


namespace :rails do

    task :env => 'setup:env' do
        # This is a hack, true, but it is the least hacky hack I could make work.
        rt = Rails.application.railties.find { |rt| rt.class == ::Sprockets::Railtie }
        rt.__send__(:run_tasks_blocks, Rails.application)
    end

    namespace :assets do
        task :clean => 'rails:env' do
            Rake::Task["assets:clobber"].invoke
        end

        task :compile => 'rails:env' do
            Rake::Task["assets:precompile"].invoke
        end

        task :recompile => [ :clean, :compile ]
    end

    desc 'Print out all defined routes in match order, with names. Target specific controller with CONTROLLER=x.'
    task :routes => :env do
        Rails.application.reload_routes!
        all_routes = Rails.application.routes.routes

        if ENV['CONTROLLER']
            all_routes = all_routes.select{ |route| route.defaults[:controller] == ENV['CONTROLLER'] }
        end

        routes = all_routes.collect do |route|

            reqs = route.requirements.dup
            reqs[:to] = route.app unless route.app.class.name.to_s =~ /^ActionDispatch::Routing/
            reqs = reqs.empty? ? "" : reqs.inspect

            {:name => route.name.to_s, :verb => route.verb.to_s, :path => route.path, :reqs => reqs}
        end

        # Crazy why this fucking route is still here by default.  Filter it out.
        routes.reject! { |r| r[:path] =~ "/rails/info/properties" }

        name_width = routes.map{ |r| r[:name].length }.max
        verb_width = routes.map{ |r| r[:verb].length }.max
        path_width = routes.map{ |r| r[:path].source.length }.max

        routes.each do |r|
            puts "#{r[:name].rjust(name_width)} #{r[:verb].ljust(verb_width)} #{r[:path].source.ljust(path_width)} #{r[:reqs]}"
        end
    end

    desc 'Prints out your Rack middleware stack'
    task :middleware => :env do
        Rails.configuration.middleware.each do |middleware|
            puts "use #{middleware.inspect}"
        end
    end

    desc 'List versions of all Rails frameworks and the environment'
    task :about => :env do
        puts Rails::Info
    end
end
