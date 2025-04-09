## Expected Targets:
#
#  - new:sinatra - base -> tests -> db -> web -> sinatra -> finalize
#  - new:rails   - base -> tests -> db -> web -> rails   -> finalize
#  - new:daemon  - base -> tests -> db -> daemon -> finalize

require 'erb'
require 'active_support'
require 'active_support/core_ext/string'

##
## Prologue
##

APP_NAME    = ARGV[1] or raise 'no name specified; re-invoke with name as last param'
USERNAME    = WHOAMI
COMMON_DIR  = REPO_ROOT + '/common'
SUPPORT_DIR = COMMON_DIR + '/support/ruby'
DAEMONS_DIR = REPO_ROOT + '/daemons'

# Things that are interpolated through Erubis with the global binding.
TEMPLATE_ROOT = SUPPORT_DIR
TEMPLATES = {
    'gitignore.erb' => '.gitignore',
    'deps.rb.erb'   => 'config/deps.rb',
}

# Disable database.yml.erb because most apps no longer require local database.yml for dev environment
# 'database.yml.erb' => 'config/versions/database.yml.default',

# Things that are just copied.
ASSET_ROOT = SUPPORT_DIR
ASSETS = {
    'Rakefile'     => 'Rakefile',
    'Gemfile.lock' => 'Gemfile.lock',
}

SUPPORTED_DBS = [ 'default' ]

# Accumulators that get drawn from in new:finalize()
target_base = ""  # application root

links       = []  # links to make
dirs        = []  # directories to make
deps_system = []  # interpolated into config/bootstrap.rb
deps_sdn    = []  # interpolated into config/bootstrap.rb
deps_local  = []  # interpolated into config/bootstrap.rb


##
## Component Tasks
##

task 'skeleton:base' do
    %w[ app lib bin config/versions ].each do |dir|
        dirs << '/' + dir
    end

    links << [ '/', COMMON_DIR + '/support/ruby/Gemfile',      'Gemfile' ]
    links << [ '/', COMMON_DIR + '/support/ruby/Gemfile.lock', 'Gemfile.lock' ]
    links << [ '/', COMMON_DIR + '/support/ruby/Rakefile',     'Rakefile' ]

    links << [ '/',    COMMON_DIR + '/ruby/boot',  'boot' ]
    links << [ '/lib', COMMON_DIR + '/ruby',       'sdn' ]
    links << [ '/lib', COMMON_DIR + '/ruby/tasks', 'tasks' ]

    deps_system += %w[  ]
    deps_sdn    += %w[ utils log config ]
end

task 'skeleton:tests' do
    %w[ rspec features step_definitions support .empty ].each do |dir|
        dirs << '/test/' + dir
    end

    links << [ '/test/support', COMMON_DIR + '/ruby/test', 'common' ]
end

task 'skeleton:db' do
    dirs << '/db'

    models   = COMMON_DIR + "/ruby/models"
    fixtures = COMMON_DIR + "/fixtures"

    links << [ '/app', models,   "models" ]
    links << [ '/db',  fixtures, "fixtures" ]

    deps_sdn += %w[ db ]
end


task 'skeleton:web' do
    target_base = REPO_ROOT

    dirs << '/public/js'
    dirs << '/public/css'
    dirs << '/public/img'

    links << [ '/',           COMMON_DIR + '/ruby/boot/unicorn.ru', 'config.ru' ]
    links << [ '/bin',        COMMON_DIR + '/ruby/bin/console',     'console' ]
    links << [ '/public',     COMMON_DIR + '/img/favicon.ico', 'favicon.ico' ]
    links << [ '/public',     COMMON_DIR + '/fonts',           'fonts' ]
    links << [ '/public/js',  COMMON_DIR + '/js',              'common' ]
    links << [ '/public/css', COMMON_DIR + '/css',             'common' ]
    links << [ '/public/img', COMMON_DIR + '/img',             'common' ]

    ASSETS['robots.txt'] = "public/robots.txt"

    TEMPLATES["app.yml.erb"]          = "config/versions/app.yml.default"
    TEMPLATES["app.yml.live.erb"]     = "config/versions/app.yml.live"
    TEMPLATES["app.yml.staging.erb"]  = "config/versions/app.yml.staging" # start w/ copy of live
    TEMPLATES['boot_rspec.rb.erb']    = 'test/support/boot_rspec.rb'
    TEMPLATES['boot_cucumber.rb.erb'] = 'test/support/boot_cucumber.rb'
end


##
## Full-Stack Tasks
##

task 'skeleton:sinatra' do
    Rake::Task['skeleton:base'].invoke
    Rake::Task['skeleton:tests'].invoke
    Rake::Task['skeleton:db'].invoke
    Rake::Task['skeleton:web'].invoke

    dirs << '/app/urls'
    dirs << '/app/views'

    deps_system += %w[ sinatra/base sinatra/flash ]
    deps_sdn    += %w[ sinatra rails/helpers ]
    deps_local  += %w[ server ]

    ASSETS['demo.rb'] = 'app/urls/demo.rb'

    TEMPLATES['server.rb.erb'] = 'app/server.rb'

    BOOTUP_DEPS = false

    Rake::Task['skeleton:finalize'].invoke
end

task 'skeleton:rails' do
    Rake::Task['skeleton:base'].invoke
    Rake::Task['skeleton:tests'].invoke
    Rake::Task['skeleton:db'].invoke
    Rake::Task['skeleton:web'].invoke

    dirs << '/app/controllers'
    dirs << '/app/helpers'
    dirs << '/app/mailers'
    dirs << '/app/views/layouts'
    dirs << '/app/views/sessions'
    dirs << '/app/views/root'
    dirs << '/app/assets/config'
    dirs << '/app/assets/images'
    dirs << '/app/assets/javascripts'
    dirs << '/app/assets/stylesheets'
    dirs << '/config/environments'
    dirs << '/config/initializers'
    dirs << '/config/locales'
    dirs << '/lib/assets'

    links << [ '/app/assets/images',      COMMON_DIR + '/img', 'common' ]
    links << [ '/app/assets/javascripts', COMMON_DIR + '/js',  'common' ]
    links << [ '/app/assets/stylesheets', COMMON_DIR + '/css', 'common' ]

    links << [ '/config', COMMON_DIR + '/config/master.key',          'master.key' ]
    links << [ '/config', COMMON_DIR + '/config/credentials.yml.enc', 'credentials.yml.enc' ]

    ASSETS['application.html.erb']      = 'app/views/layouts/application.html.erb'
    ASSETS['mailer.html.erb']           = 'app/views/layouts/mailer.html.erb'
    ASSETS['mailer.text.erb']           = 'app/views/layouts/mailer.text.erb'
    ASSETS['sessions_new.html.erb']     = 'app/views/sessions/new.html.erb'
    ASSETS['root_index.html.erb']       = 'app/views/root/index.html.erb'
    ASSETS['application_helper.rb']     = 'app/helpers/application_helper.rb'
    ASSETS['application_controller.rb'] = 'app/controllers/application_controller.rb'
    ASSETS['root_controller.rb']        = 'app/controllers/root_controller.rb'
    ASSETS['sessions_controller.rb']    = 'app/controllers/sessions_controller.rb'
    ASSETS['application_mailer.rb']     = 'app/mailers/application_mailer.rb'
    ASSETS['application.scss']          = 'app/assets/stylesheets/application.scss'
    ASSETS['application.js']            = 'app/assets/javascripts/application.js'
    ASSETS['manifest.js']               = 'app/assets/config/manifest.js'
    ASSETS['404.html']                  = 'public/404.html'
    ASSETS['422.html']                  = 'public/422.html'
    ASSETS['500.html']                  = 'public/500.html'
    ASSETS['en.yml']                    = 'config/locales/en.yml'
    ASSETS['boot.rb']                   = 'config/boot.rb'
    ASSETS['environment.rb']            = 'config/environment.rb'
    ASSETS['routes.rb']                 = 'config/routes.rb'
    ASSETS['development.rb']            = 'config/environments/development.rb'
    ASSETS['test.rb']                   = 'config/environments/test.rb'
    ASSETS['production.rb']             = 'config/environments/production.rb'
    ASSETS['scheduler.rb']              = 'config/initializers/scheduler.rb'

    TEMPLATES['application.rb.erb']     = 'config/application.rb'

    BOOTUP_DEPS = true

    Rake::Task['skeleton:finalize'].invoke
end

task 'skeleton:daemon' do
    target_base    = DAEMONS_DIR
    daemon_support = DAEMONS_DIR + "/support"

    Rake::Task['skeleton:base'].invoke
    Rake::Task['skeleton:tests'].invoke
    Rake::Task['skeleton:db'].invoke

    dirs << '/views'

    links << [ '/bin', daemon_support + "/console",   'console' ]
    links << [ '/bin', daemon_support + "/run",       'run' ]
    links << [ '/bin', daemon_support + "/launch",    'launch' ]
    links << [ '/',    daemon_support + "/config.ru", 'config.ru' ]

    deps_sdn    += %w[ mcp/daemon ]
    deps_local  += [ APP_NAME.downcase ]

    TEMPLATES['daemon.rb.erb']        = "app/#{APP_NAME.downcase}.rb"
    TEMPLATES['boot_rspec.rb.erb']    = 'test/support/boot_rspec.rb'
    TEMPLATES['boot_cucumber.rb.erb'] = 'test/support/boot_cucumber.rb'

    TEMPLATES["daemon.yml.erb"]         = "config/versions/app.yml.default"
    TEMPLATES["daemon.yml.live.erb"]    = "config/versions/app.yml.live"
    TEMPLATES["daemon.yml.staging.erb"] = "config/versions/app.yml.staging"

    BOOTUP_DEPS = false

    Rake::Task['skeleton:finalize'].invoke
end


task 'skeleton:finalize' do
    target_dir = target_base + '/' + APP_NAME

    raise "cannot make new: #{target_dir} exists" if File.exists?(target_dir)

    dirs.unshift('/').each do |dir|
        make_dir(File.expand_path(target_dir + '/' + dir))
    end

    links.each do |inside, from, to|
        make_link(File.expand_path(target_dir + '/' + inside), from, to)
    end

    ## Set all variables necessary to interpolate into templates.
    SYSTEM_DEPS = deps_system.map { |d| "require '#{d}'\n" }
    SDN_DEPS    = deps_sdn.map    { |d| "require 'sdn/#{d}'\n" }
    LOCAL_DEPS  = deps_local.map  { |d| "require 'app/#{d}'\n" }

    TEMPLATES.each_pair do |from, targets|
        Array(targets).each do |to|
            to.insert(0, target_dir + '/') unless to[0] == ?/
            interpolate_file(from, to, binding)
        end
    end

    ASSETS.each_pair do |from, targets|
        Array(targets).each do |to|
            to.insert(0, target_dir + '/') unless to[0] == ?/

            copy_asset_file(from, to)
        end
    end

    Dir.chdir(target_dir) do
        Rake::Task['config'].invoke
        system("bundle install")
        `git add -fA .`
    end

    puts
    puts "***"
    puts "*** New application #{APP_NAME} created at #{target_dir} (and added to GIT)."
    puts "***"
    puts

    exit # otherwise rake will process the next cmdline option
end


##
## UTIL
##

# Convert normal paths to non-rubygems-versionable base paths (for use in
# linking vendor gems).
def sanitize_gempath(path)
    path.gsub(/.git/, '').gsub(/-/, '_').gsub(%r{^.*/([^/]+)$}, '\1')
end

# Dupe the inputs because they might be frozen.
def interpolate_file(_from, _to, binding)
    from = _from.dup
    to   = _to.dup

    from.insert(0, TEMPLATE_ROOT + '/') unless from[0] == ?/

    puts "template: #{from} -> #{to}"
    template = File.open(from).read
    output   = ERB.new(template).result(binding)
    File.open(to, "w") { |f| f.write(output) }
end

def copy_asset_file(_from, _to)
    from = _from.dup
    to   = _to.dup

    from.insert(0, ASSET_ROOT + '/') unless from[0] == ?/

    puts "copy: #{from} -> #{to}"
    `cp #{from} #{to}`
end

# Make a symlink with the repo-root-relative path for it (so that links work regardless of
# repo/checkout location).
def make_link(inside, from, to)
    Dir.chdir(inside) do
        from.gsub!(/#{REPO_ROOT}/, '')
        dots = inside.gsub(/#{REPO_ROOT}/, '').count('/')
        from = from.insert(0, '../' * dots).squeeze('/')

        warn "link: src #{from} doesn't exist" unless File.exists?(from)

        puts "link: #{from} -> #{inside}/#{to}"
        `ln -s #{from} #{to}`
    end
end

def make_dir(dir)
    puts "mkdir: #{dir}"
    `mkdir -p #{dir}`
    `touch #{dir}/.keep`
end
