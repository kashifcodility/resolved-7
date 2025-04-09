return if WHOAMI rescue false

##
## Core utils for *Rakefiles* ONLY.  This file MUST be kept *light* -- only
## truly common constants and functions go in here.
##

##
## General utility functions - have to start with these so we can use them
## below/following.
##

# Monkey patch to allow overriding defined rake tasks (instead of
# adding to them, which is the default behaviour when specifying tasks
# >1 times).

Rake::TaskManager.class_eval do
    def remove_task(task_name)
        @tasks.delete(task_name)
    end

    def remove_task_ref(task_name)
        @top_level_tasks.delete(task_name)
    end
end

def remove_task_ref(task)
    Rake.application.remove_task_ref(task.to_s) != nil
end

def remove_task(task)
    task = task.name unless [ String, Symbol ].include?(task.class)
    task = task.to_s

    raise "unknown task [#{task}] to remove" unless Rake.application.lookup(task)

    Rake.application.remove_task(task) != nil
end

# Find root in other directories, maxdepth 3.  Assumes that people are running
# apps off a common root.

def locate_up_path(opts = {}, &what)
    depth = opts[:maxdepth] || 3
    dir = Dir.pwd

    begin
        return File.expand_path(dir) if what.call(dir)
        dir = File.expand_path(dir + "/..")
        depth -= 1
    end until depth == 0 or dir == '/'

    return nil
end

##
## Core Setup (Envariables, constants, load paths, etc).
##

# If you want to use an env variable that's NOT capitalized, we'll caps it for
# you.
ENV.each {|name, value| ENV[name.upcase] ||= value}

# Used elsewhere in other app Rakefiles to avoid setting up fixtures (e.g.).
#
# NOTE: For OS_PLATFORM, if we get back empty string (in *NIX, uname not found,
# but that's grossly unlikely) or it throws an exception (`` with unknown
# command raises), we presume win32.
WHOAMI           = ENV['USER'] || `whoami`.chomp || raise rescue 'UNKNOWN'
OS_PLATFORM      = `uname -s`.chomp.downcase || raise rescue 'win32'

IS_WINDOWS       = (RUBY_PLATFORM =~ /mswin|win32|mingw|bccwin|cygwin/)

REPO_ROOT        = locate_up_path { |dir| File.directory?(dir + "/.git") }
DATASOURCES_ROOT = (REPO_ROOT + '/common/datasources' rescue '/srv/datasources')
GEM_ROOT         = File.expand_path(File.exists?(dir = Dir.pwd + "/vendor") ? dir : REPO_ROOT + "/common/gems")

# Always add the common/tasks directory to the load path.
$:.unshift File.dirname(__FILE__)

# Make all referenced GEM lib folders part of our load path.  This enables
# require 'gemname' shit to work without having to load an app's 'boot/init'.
$:.unshift(*Dir[GEM_ROOT + "/{*,*/*}/lib"].reject { |n| n =~ /rails.git/ })

if REPO_ROOT
    $:.unshift(REPO_ROOT)
    # Add frontend lib to the path, so that we can do require as if we are in an
    # e.g. app require 'sdn/gems' This prevents the library from being required
    # twice.
    $:.unshift(REPO_ROOT + '/frontend/lib/')
else
    # Assume you are in the production application dir
    $:.unshift(File.expand_path('./lib/'))
end

# Require commonly used gems
require 'rubygems'

# Defang rubygems, so that gems with pedantic dependencies can be loadded
require 'sdn/gems'
require 'json'
require 'erb'
require 'fileutils'
require 'pp'
require 'yaml'
require 'set'
require 'byebug'

require 'sdn/utils/object' # for #const_def

# Finally, load all tasks that should be repo-wide (in- or out-side apps).
load 'common.rake'
