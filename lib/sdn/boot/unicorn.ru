# Unicorn-based config.ru.  If someone manages to still type rackup, we re-run
# ourselves with the proper invocation of unicorn.  Actually, turns out that's
# the best way to do it, since unicorn doesn't look for config files by default.
#
# NOTE: When being forked (in unicorn worker case), $0 == "unicorn worker[0]
# -l0.0.0.0:8080".
ru = nil

case $0
when /rackup/ then

    case Rack::VERSION
    when [1, 1], [1, 2], [1, 3] then
        options = nil
        ObjectSpace.each_object(Rack::Server) do |c|
            raise "** WARNING: more than one rack server instance detected" if options
            options = c.options
        end

        raise "** FATAL: unable to find the rack server instance" unless options
    end

    # Try to detect whether cmdline options were set.  Our scripts honor cmdline
    # args as the master override, but if we always pass in -o/-p, then they
    # will always override .yml settings/defaults.
    args = []
    args << "-o #{options[:Host]}" if options[:Host] != "localhost"
    args << "-p #{options[:Port]}" if options[:Port] != 9292
    args = args * " "

    case `which unicorn`.chomp.length
    when 0 then
        type = File.exists?('config/routes.rb') ? 'rails' : 'sinatra'
        cmd = "rackup #{args} boot/#{type}.ru" # Fallback

        puts "** WARNING ** can't find unicorn, please: sudo gem install unicorn --version=1.1.4"
        puts "** WARNING ** falling back to: #{cmd}"
        sleep 3

    else
        cmd = "unicorn #{args} -c boot/unicorn.rb"
    end

    cmd.insert(0, "ARGS='#{args}' ")

    Kernel.exec(cmd)
when /unicorn/ then
    # You're better off just continuing to run rackup -- otherwise, run this as
    # "unicorn -c boot/unicorn.rb".
else
    # We're probably running under something else, in which case we need to
    # pretend to have been one of the other *.ru's to begin with.  The idea is
    # that this should probably keep us working properly under Phusion, should
    # we have to.
    #
    # NOTE: untested as of yet!
    type = const_defined? RAILS_GEM_VERSION ? 'rails' : 'sinatra'
    ru   = File.read("boot/#{type}.ru")
    eval ru
    exit 0
end

# <APPNAME>::Application == Rails
# ::Server == Sinatra, if and when
rack_app = APPNAME.constantize::Application rescue ::Server

map (rack_app.config.relative_url_root rescue "/") || "/" do
    run rack_app
end
