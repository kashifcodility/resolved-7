# Half-intelligent MonkeyPatch loader.
#
# RULES
#
# (0) Patches go in common/lib/patches/*, named after their purpose and
#     commented with some reasonable context.  Chances are no one is going to
#     review it for a long while, so capturing the context for the next upgrade
#     opportunity is critical.
#
# (1) We're a MonkeyPatch loader, so we should only responsible for loading
#     patches to *existing* classes.  If you're *adding* something new, then you
#     should be doing something in common/lib/utils/* instead (util == core_ext
#     in our lexicon).
#
# (2) Patches should not address top-level Objects directly - root "::" prefixes
#     should be omitted.  Otherwise this could circumvent the Sandbox (and we
#     don't want to waste time working out binding protection, etc).
#
# (3) Patches should not combine declarations of nested scopes (e.g. "class
#     Foo::Bar .. end").  Patches are evaluated inside an empty module space,
#     which means that non-built-in class/module types aren't present, thus the
#     patch would error out.
#
# CAVEATS
#
# - If you're aliasing a method in your patch, you'll get an exception unless
#   you do something like:
#
#    module Module
#        alias new_method old_method if instance_methods.include?("old_method")  # ruby 1.8
#        alias new_method old_method if instance_methods.include?(:old_method)  # ruby 1.9
#        ...
#    end
#

module SDN
module Patcher
    extend self

    DEFAULT_PATCH_DIR = File.dirname(__FILE__) + '/patches'

    class Sandbox < Module; end

    def patch!(patch_dir = DEFAULT_PATCH_DIR)
        unless File.directory?(patch_dir)
            $LOG.error "unable to find patch directory at #{patch_dir}"
            return
        end

        applied = []
        skipped = []

        Dir[patch_dir / "*.rb"].each do |patch|
            patch_name = File.basename(patch)

            begin
                sandbox = Sandbox.new
                source  = File.read(patch)

                # 1. Load the code into a sandbox module.
                # 2. Get all constants defined under the sandbox module.
                # 3. Reduce constant list to any that don't actually exist.
                # 4. If any remain, then fail the patch.
                #
                # Doing Kernel.eval() is the quickest way to test for
                # pre-existence of an arbitrarily-nested constant.  Otherwise
                # you'd have to walk from Object down each nested scope, which
                # is more complicated logic and wouldn't necessarily be faster.

                sandbox.module_eval(source)

                defined_consts = all_constants_for(sandbox)
                missing_consts = defined_consts.select do |constant|
                    begin
                        Kernel.eval(constant)
                        false
                    rescue
                        true
                    end
                end

                if missing_consts.empty?
                    require patch
                    applied << patch_name
                else
                    skipped << [ patch_name, missing_consts ]
                end

            rescue => e
                $LOG.error(e) { "Failed Patch: #{patch_name}" }
            end
        end

        $LOG.debug "Patcher: applied #{applied.size} patches" if applied.any?
        skipped.each do |name, missing|
            $LOG.debug "Patcher: skipped #{name} (#{missing * ', '} not present)"
        end

    end

    protected

    # Returns a single-depth Array of strings, each representing a class or
    # module.  e.g. [ "Foo", "Foo::Bar", "Foo::Bar::Blort" ].
    def all_constants_for(constant, root = nil)
        return nested_classes_for(constant, root).flatten.map { |c| c.gsub(/^[^>]+>::/, '') }
    end

    # Only interested in constants that respond to "constants", hence the
    # kind_of? filter.
    def nested_classes_for(constant, root = nil)
        new_root = root ? root.const_get(constant) : constant
        return [] unless new_root.kind_of? ::Module
        new_root.constants.map { |c| new_root.inspect + "::" + c.to_s } +
            new_root.constants.map { |c| nested_classes_for(c, new_root) }
    end

end
end

SDN::Patcher.patch!
