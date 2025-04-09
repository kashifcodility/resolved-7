##
## Deployment functionality for simplifying converting various trees between "debug"
## (internal development) and "release" (public LIVE) versions.
##
#
# Discussion:
#
# Gotcha #1: If someone had a config/versions/newrelic.yml.WHOAMI, *that* would overwrite
# the direct symlink that had been previously created to common/config/newrelic.yml.
#
# Gotcha #2: We need to be able to wipe all *.yml* on every deploy, so where not everyone
# has the same local / global YAMLs (so if you have one laying around from a previous
# deploy (think deploy:live, deploy:staging, or someone else's tree), you'd still inherit
# it.
#
# So the deploy steps simplify to:
#
#    1. */config/versions/*.yml.WHOAMI  -> */config/*.yml
#    2. */config/versions/*.yml.all     -> */config/*.yml        (.all always wins symlink)
#    3. common/config/*.yml.WHOAMI      -> */config/*.yml.global
#    4. common/config/*.yml.all         -> */config/*.yml.global (.all always wins symlink)
#
# NOTE: If you're a new user and have ZERO configurations app-local , deploy will
# auto-copy */config/*.yml.default to */config/*.yml.WHOAMI first (same for globals),
# auto-git-add them for you then continue with deployment (symlinking).  Alternatively,
# you can force this behaviour to occur no matter what with ``rake deploy:defaults''.
#
# NOTE: ::SDN::Config behaviour is to always load FILE.yml.global first, then
# merge FILE.yml on top of it via Hash.deep_merge (local configurations always
# win leaf-key collisions).
#
# NOTE: (2) was created specifically for {newrelic, facebooker}.yml files, which live in
# common/config.  These were originally directly symlinked into the local config
# directories of apps that needed them, and were never expected to be touched.  We can't
# rely on that anymore, so the policy for 3rd-party YAMLs is now:
#
#   * If specific to a single app, it should be placed in */config/versions/*.yml.all.
#
#   * If common across >1 application (newrelic), it should be placed in
#     common/config/FILE.yml, and symlinks from the YAML to */config/versions/FILE.yml.all
#     should be placed in the relevant applications.
#
# Understand that (4) is generally not useful for (2)'s purpose since no 3rd party library
# expects to load FILE.yml.global (wants YML extension, typically).

require 'pathname'

##
## Constants
##

# Where global configurations are stored, relative to application.
ALL_CONFIG_PATHS = [
    GLOBAL_CONFIG_PATH = Pathname.new(REPO_ROOT + "/common/config").relative_path_from(Pathname.new(Dir.pwd)).to_s,
    LOCAL_CONFIG_PATH  = "config/versions",
]

TARGET_CONFIG_PATH = "config"


##
## Targets
##

namespace :setup do

    task :config do
        do_deploy(WHOAMI)
    end

    namespace :config do

        task :defaults do
            copy_default_yamls_for(WHOAMI, ALL_CONFIG_PATHS)
            do_deploy(WHOAMI)
        end

        task :fresh do
            wipe_yamls_for(WHOAMI, ALL_CONFIG_PATHS)
            Rake::Task['setup:config:defaults'].invoke
        end

        task :staging do
            do_deploy('staging')
        end

        task :live do
            do_deploy('live')
        end

    end
end

##
## Utility methods
##

def do_deploy(for_whom)
    # Auto-copy defaults over for any file that the user doesn't have in the
    # specified path.
    ALL_CONFIG_PATHS.each do |path|
        copy_missing_yamls_for(for_whom, path)
    end

    link_yamls_for(for_whom)
end

def yamls_for(extension, path)
    Dir["{#{Array(path) * ','}}/*.yml.#{extension}"]
end

def copy_missing_yamls_for(extension, path)
    missing = yamls_for('default', path).map { |f| f.sub(/.[^\.]+$/, '') } -
              yamls_for(extension, path).map { |f| f.sub(/.[^\.]+$/, '') }

    return if missing.empty?

    missing.each do |file|
        from = file + ".default"
        to   = file + "." + extension

        copy_yaml(from, to)
    end
end

def copy_default_yamls_for(extension, path)
    yamls_for('default', path).each do |file|
        from = file
        to   = file.sub(/default$/, extension)

        copy_yaml(from, to)
    end
end

def copy_yaml(from, to, add_to_git = true)
    system("cp -f #{from} #{to}")

    return unless add_to_git

    STDOUT.puts "initializing: #{from} -> #{to} (added to GIT)"
    system("git add -f #{to}")
end

def wipe_yamls_for(extension, path)
    yamls_for(extension, path).each do |file|
        STDOUT.puts "nuking: #{file} (removed from GIT)"
        system("git rm -f #{file}")
    end
end

def link_yamls_for(extension)
    # First wipe any pre-existing YAMLs.
    # Ubuntu use dash as default shell, however, dash does not support brace expansion
    # Need to use bash as workaround or use ruby's native command
    # system("bash -c 'rm -f #{TARGET_CONFIG_PATH}/*.yml{,.global}'")
    Dir["#{TARGET_CONFIG_PATH}/*.yml{,.global}"].each do |filename|
        File.delete(filename)
    end

    # Next link in the app-local configs.
    link_primary_yamls_for(extension)
    link_primary_yamls_for('all')

    # Finally link in the global config versions.
    link_global_yamls_for(extension)
    link_global_yamls_for('all')
end

def link_primary_yamls_for(extension)
    yamls_for(extension, LOCAL_CONFIG_PATH).each do |file|
        from = "versions/#{File.basename(file)}"

        file.slice!(".#{extension}")
        to = "#{TARGET_CONFIG_PATH}/#{File.basename(file)}"

        system("rm -f #{to}")
        system("ln -vs #{from} #{to}")
    end
end

def link_global_yamls_for(extension)
    global_config_path = GLOBAL_CONFIG_PATH

    yamls_for(extension, global_config_path).each do |file|
        from = "../#{file}"

        file.slice!(".#{extension}")
        to = "#{TARGET_CONFIG_PATH}/#{File.basename(file)}.global"

        system("rm -f #{to}")
        system("ln -vs #{from} #{to}")
    end
end
