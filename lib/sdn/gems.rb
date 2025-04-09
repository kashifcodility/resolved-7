module SDN
    module Gems
        extend self

        def defang!
            Kernel.module_eval do
                alias :old_gem :gem
                def gem(*args)
                    raise LoadError if args.first == 'mongrel_experimental'
                    raise Gem::LoadError if args.first == 'i18n'
                end

                alias :old_require :require
                def require(thing)
                    return false if ::SDN::Gems.ignored_requires.include? thing
                    return old_require(thing)
                end
            end
        end

        def refang!
            Kernel.module_eval do
                alias :gem :old_gem
            end
        end

        def fanged(&block)
            refang!
            block.call
            defang!
        end

        # Pull in all single-gems from RubyGem's paths into the LOAD_PATH.  We
        # say single-gem because we're deliberately trying to bypass Gem's
        # version management mechanism: if there is more than one gem, then we'd
        # be including the same gem multiple times (multiple versions) into the
        # load path, and that would likely have bad consequences.  Still means
        # RubyGems will kick in on things that aren't in the path, but it should
        # be far fewer times, and I hope therefore cause far fewer headaches.
        def update_load_path
            # Walk each known gem root, pull out any gem lib dirs, group on the
            # gem name, and only keep gem paths that have only one version.
            single_paths = Dir["{#{Gem.path * ','}}/gems/*/lib"].group_by do |p|
                File.basename(File.dirname(p).sub(%r{-[\d\.]+[a-zA-Z]*$}, ''))
            end.reject { |k, v| v.length > 1 }

            $:.push(*single_paths.values.flatten)
        end

        # While defanged, also provide facility to prevent entire files from
        # being require'd.  Initially, this is because mongoid's main require
        # auto-require's mongoid/railtie if Rails is defined, and the railtie
        # hooks all sorts of automatic shit.  And I don't want to fork the repo
        # just for this goddamn thing. FKRS!
        def ignore_require_for(thing)
            self.ignored_requires << thing
        end

        attr_accessor :ignored_requires
        self.ignored_requires = []

    end
end

::SDN::Gems.update_load_path
::SDN::Gems.defang!
