# Generic framework loader for scripts (including our console).
#
# Author: Jordan Ritter <jpr5@sdninc.co>

def find_up_path(look_for)
    dir = File.expand_path(__FILE__)

    until dir == "/" || dir.empty? do
        path = dir + File::SEPARATOR + look_for
        break if File.directory?(path)
        path = nil
        dir = dir.split(File::SEPARATOR)[0..-2].join(File::SEPARATOR)
    end

    return path
end

def bail(e)
    puts "Unable to boot console: "
    puts "    #{e.class}: #{e.message}"
    puts "    " + e.backtrace[0..2].inspect rescue ""
    puts "Search paths: #{$boot_paths.join(", ")}"
    exit 1
end

###
### MAIN
###

$SDN_CONSOLE = true

# Try from the base path of wherever this file is located, otherwise search up
# to find a known-usable app dir to boot from.
$boot_paths = [
    Dir.pwd,
    File.dirname(File.expand_path(__FILE__ + "/..")),
    find_up_path("api2"),
    find_up_path("frontend"),
].compact

boot_path = $boot_paths.compact.find do |app_path|
    File.exists? app_path + "/Rakefile"
end

bail(RuntimeError.new("couldn't find bootable path")) unless boot_path

begin
    Dir.chdir(boot_path) do
        $:.unshift File.expand_path(".")
        require 'boot/init'
        puts "Booted from: #{boot_path}"
    end
rescue Exception => e
    bail(e)
end

require 'pp'

# Disable logging to syslog, enable to console
$LOG.configure(:console => true, :syslog => nil) if $LOG
