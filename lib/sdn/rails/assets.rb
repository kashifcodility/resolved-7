#
# Utility classes for dealing with Rails assets and the Asset Pipeline
#   http://guides.rubyonrails.org/asset_pipeline.html
#   often used in Rake tasks, particularly assets:*
#
require 'ostruct'
require 'fileutils'
require 'pathname'
require 'uri'

module SDN::Rails
module Assets
    module Exceptions
        class Error         < Exception; end
        class ArgumentError < Error;     end
        class LocateError   < Error;     end
    end

    class Manager
        include Exceptions

        def self.for_app_name(name)
            return self.new(name)
        end

        def self.for_rails(instance = nil)
            instance ||= ::Rails if Object.const_defined?(:Rails)
            return self.new(nil, instance)
        end


        attr_reader :app_name, :app_root, :config, :env
        attr_reader :asset_map

        def initialize(name, rails_instance = nil)
            @asset_map = {}

            if name
                @app_name = name
                @app_root = Pathname.new(SDNROOT).parent.join(name).cleanpath
                @config   = OpenStruct.new(:prefix => 'assets')
                @env      = OpenStruct.new
                return self
            end

            if rails_instance
                @app_root  = Pathname.new(rails_instance.root)
                @app_name  = File.basename(@app_root)
                @config    = rails_instance.application.config.assets
                @env       = rails_instance.application.assets
                @for_rails = true
                return self
            end

            raise ArgumentError, "no source for #initialize"
        end
        protected :initialize


        def for_rails?
            return !! @for_rails
        end

        def assets
            return self.asset_map.values
        end

        def located?(logical_path)
            return self.asset_map.include?(logical_path)
        end

        def asset_prefix
            return (@asset_prefix ||= self.config.prefix.to_s.gsub(File::SEPARATOR, ''))
        end
        def app_assets_path
            return (@app_assets_path ||= self.app_root.join('app', self.asset_prefix))
        end
        def app_processor_dirs
            return (@app_processor_dirs ||= self.app_assets_path.children.select {|pathname| pathname.directory? })
        end

        def public_assets_path
            return (@public_assets_path ||= self.app_root.join('public', self.asset_prefix))
        end


        def locate_original_by_logical_path(logical_path)
            return nil unless logical_path.present?

            # already cached?
            return self.asset_map[logical_path] if self.located?(logical_path)

            unless asset = self.locate_original_asset(logical_path)
                # that's not likely to happen ... except in ONE GODDAMN CASE
                #   Sprockets::StaticCompiler#compile reduces 'path/index.ext' => 'path.ext'
                #   because it thinks it's smart.  we have to de-engineer that,
                #   AND we must consider extension processing ('.erb', '.coffee', etc.)
                indexy_path = logical_path.sub(/\./, '/index.')
                asset = self.locate_original_asset(indexy_path, logical_path)
            end

            # cache non-nil only
            self.asset_map[logical_path] = asset if asset

            return asset
        end
        alias :locate_original :locate_original_by_logical_path

        def locate_original_asset(locate_path, logical_path = nil)
            logical_path ||= locate_path

            # where is it within app/assets?
            #   the logical_path alone doesn't tell us that, but we can sniff it out.
            #   - we must check each of the 'processor' directories,
            #   - we must consider extension processing ('.erb', '.coffee', etc.)
            #     since logical_path is just the target filename.
            self.app_processor_dirs.each do |processor_dir|
                glob = Pathname.glob(processor_dir.join("#{locate_path}{,.*}"))
                next false unless (glob.size == 1)

                physical_path = glob.first
                next false unless File.file?(physical_path)

                # there you go!
                return Asset.new(self, logical_path, physical_path, processor_dir)
            end

            return nil
        end
        protected :locate_original_asset


        # converts a path or URL -- any /-delimited String -- to a logical path,
        # within reason
        def path_to_logical(path)
            return path unless path.present?

            path = URI.parse(path).path
            parts = path.split(File::SEPARATOR).select {|part| part.present? }
            parts.shift if (parts.first == self.asset_prefix)
            return File.join(parts)
        rescue
            raise ArgumentError, "cannot parse the path #{path.inspect}"
        end

        def locate_compiled_by_logical_path(logical_path)
            return nil unless logical_path.present?

            # already cached?
            return self.asset_map[logical_path] if self.located?(logical_path)

            # is it present within public/assets?
            #   no extension or magic-'index'-renaming required here
            physical_path = self.public_assets_path.join(logical_path)
            return nil unless physical_path.file?

            # construct and cache
            asset = Asset.new(self, logical_path, physical_path)
            self.asset_map[logical_path] = asset

            return asset
        end
        alias :locate_compiled :locate_compiled_by_logical_path
    end


    class Compiler < Manager
        def manifest?
            return (!! self.config.digest)
        end
        def manifest_path
            return (@manifest_path ||= Pathname.new(self.config.manifest || self.public_assets_path))
        end
        def manifest_file
            return manifest_path.join('manifest.yml')
        end


        def compile!
            raise ArgumentError, "the Compiler must be constructed #for_rails" unless self.for_rails?

            self.compile_assets!
            self.copy_assets!

            return self
        end

        def clean!
            [ self.app_root.join('tmp/cache'), self.public_assets_path ].each do |pathname|
                pathname.rmtree if pathname.exist?
            end

            return self
        end

        def recompile!
            return self.clean!.compile!
        end


        protected

        def compile_assets!
            self.config.compile = true
            self.config.digests = {}
            self.config.digest = true

            self.env.logger = $LOG

            # custom pre-compile filter for our JavaScript files
            #   http://guides.rubyonrails.org/asset_pipeline.html
            #   "The default matcher for compiling files includes application.js, application.css
            #    and all non-JS/CSS files"
            # this will passively populate our #asset_map
            self.config.precompile << Proc.new do |logical_path|
                if self.located?(logical_path)
                    # we've already seen it, and that's really really bad
                    #   it's likely a 'path.ext' + 'path/index.ext' overlapping each other,
                    #   and that's a bad practice
                    raise LocateError, "more than one logical path resolves to #{logical_path}.  fix this!"
                end

                unless asset = self.locate_original(logical_path)
                    # our app doesn't own this file
                    #   eg. 'twitter/bootstrap.js', from the bootstrap-rails gem
                    $LOG.debug("#{logical_path}: could not locate")
                    next nil
                end

                # it knows whether it's suitable or not
                next false unless asset.precompile?

                $LOG.info "#{asset.processor} : #{asset.relative_path} => #{asset.logical_path}"
                next true
            end

            compiler = ::Sprockets::StaticCompiler.new(
                self.env,
                self.public_assets_path,
                self.config.precompile,
                {
                    :digest        => self.config.digest,
                    :manifest      => self.manifest?,
                    :manifest_path => self.manifest_path,
                }
            )

            # this is how you configure your JavaScript compressor:
            #   open the damn class and fuck with it.
            #   i don't see how options can be passed in Rails 3.2.8
            case self.config.js_compressor
                when :uglifier
                    # we want just the absolute minimum of compression:
                    #   remove comments
                    #   and output with intented syntactic lines (whitespace compresses well)
                    ::Uglifier::DEFAULTS.merge!({
                        :mangle        => false,
                        :toplevel      => false,
                        :squeeze       => false,
                        :seqs          => false,
                        :dead_code     => false,
                        :lift_vars     => false,
                        :unsafe        => false,
                        :copyright     => false, # useless; it only keeps the FIRST copyright :)
                        :ascii_only    => false,
                        :inline_script => false,
                        :quote_keys    => false,
                        :beautify      => true,
			:harmony       => true, # allows for ES6 syntax
                    })
            end

            compiler.compile
        end

        def copy_assets!
            assets_to_copy = self.assets.select {|asset| asset.copy? }
            return unless assets_to_copy.present?

            # now, some file copying
            #   to keep assets away from compilation, compression, etc.
            #   and they have to go into the manifest
            # now this might seem janky, but believe me
            #   trying to monkey-patch this shit into Sprockets + Railties + Rails?
            #   this is much fucking easier
            # TODO:  digest-stamping the copies
            #   the files we care about having copied are generally non-changing,
            #   as in -- 'so ancient we don't want to drudge up a 2-year old
            #   compatible non-compressed version of it', leave-it-alone
            #   kind of legacy stuff
            if self.manifest?
                manifest = self.manifest_file.open('r') {|f| YAML.load(f.read) }
            end

            assets_to_copy.each do |asset|
                $LOG.info "copy : #{asset.relative_path}"

                from_path     = self.app_assets_path.join(asset.processor_path)
                to_path       = self.public_assets_path.join(asset.relative_path)

                to_path.parent.cleanpath.mkpath
                FileUtils.cp(from_path, to_path)

                if self.manifest?
                    # register it in the manifest
                    manifest[asset.logical_path.to_s] = asset.relative_path.to_s
                end
            end

            if self.manifest?
                self.manifest_file.open('wb') {|f| YAML.dump(manifest, f) }
            end
        end
    end


    class Asset
        const_def :REQUIRE_EXPRESSION, '=\s+require(?:|_tree|_self|_directory)(?:\s+|\Z)'
        const_def :JAVASCRIPTS_REQUIRE_REGEXP, %r{\A\s*//#{REQUIRE_EXPRESSION}} # //= require...
        const_def :JAVASCRIPTS_EXTENSION, '.js'
        const_def :STYLESHEETS_REQUIRE_REGEXP, %r{\A\s*\*#{REQUIRE_EXPRESSION}} # *= require...
        const_def :STYLESHEETS_OPEN_COMMENT_REGEXP, /\/\*/                      # /*
        const_def :STYLESHEETS_CLOSE_COMMENT_REGEXP, /\*\//                     # */
        const_def :STYLESHEETS_EXTENSION, '.css'


        attr_reader :manager
        attr_reader :logical_path, :physical_path, :relative_path
        attr_reader :processor, :processor_dir

        def initialize(manager, logical_path, physical_path, processor_dir = nil)
            @manager       = manager
            @logical_path  = Pathname.new(logical_path)
            @processor_dir = processor_dir
            @physical_path = physical_path

            if processor_dir
                @relative_path = physical_path.sub("#{processor_dir}/", '')
                @processor     = File.basename(processor_dir).to_sym
            else
                @relative_path = self.logical_path
                @processor = case self.logical_path.extname
                    when JAVASCRIPTS_EXTENSION then :javascripts
                    when STYLESHEETS_EXTENSION then :stylesheets
                    else nil
                end
            end

            # determined on-the-fly
            @precompile    = nil
            @has_directive = nil
            @copy          = nil
        end

        def to_s
            return self.logical_path.to_s
        end


        # simply the #relative_path preceded with the #processor,
        # so it's still relative
        def processor_path
            return nil unless self.processor
            return Pathname.new(File.join(self.processor.to_s, self.relative_path))
        end

        def javascript?
            return (self.processor == :javascripts)
        end
        alias :js? :javascript?

        def stylesheet?
            return (self.processor == :stylesheets)
        end
        alias :css? :stylesheet?

        def image?
            return (self.processor == :images)
        end


        def precompile?
            return @precompile unless @precompile.nil?

            if self.relative_path.to_s.include?(File::SEPARATOR)
                # keep a copy of everything under a top-level symlinked directory
                #   by default, only the NON- *.css and *.js files are copied.
                #   these files should not be subjected to compilation, compression, etc.
                #   and may be explcitly included.
                top_level = self.relative_path.to_s.split(File::SEPARATOR).first
                if self.processor_dir && self.processor_dir.join(top_level).symlink?
                    $LOG.debug("#{self.logical_path}: #{top_level.inspect} directory is a symlink, copying ...")
                    @copy = true
                    return (@precompile = false)
                end
            end

            # always precompile images
            return (@precompile = true) if (self.processor == :images)

            # precompile the asset if the filename required extension processing
            #   physical path is the current reality,
            #   logical path is the resulting name and extension
            return (@precompile = true) unless (self.physical_path.extname == self.logical_path.extname)

            # precompile it if the file contains a supported asset pipeline directive
            return (@precompile = true) if self.has_directive?

            # even without a directive ...
            #   it's ours, it's important, and it turns out that we need to precompile it.
            #   if the 'application' asset has every dependency that your 'page' asset needs,
            #   your 'page' asset could easily be 100% code and have no directive
            return (@precompile = true)
        end

        def has_directive?
            return @has_directive unless @has_directive.nil?

            # images don't have directives
            return (@has_directive = false) if (self.processor == :images)

            # scan through the ENTIRE file, to avoid assumptions about how blank lines,
            #   block comments, etc. are interpreted by Sprockets
            comment_depth = 0

            physical_path.open('r') do |handle|
                while line = handle.gets("\n")
                    next if line.blank?

                    case processor
                        when :javascripts
                            return (@has_directive = true) if (line =~ JAVASCRIPTS_REQUIRE_REGEXP)

                        when :stylesheets
                            # opening comments
                            comment_depth += line.scan(STYLESHEETS_OPEN_COMMENT_REGEXP).size
                            if comment_depth > 0
                                return (@has_directive = true) if (line =~ STYLESHEETS_REQUIRE_REGEXP)
                            end

                            # closing comments
                            comment_depth -= line.scan(STYLESHEETS_CLOSE_COMMENT_REGEXP).size

                        else
                            raise LocateError, "#{logical_path}: unknown processor #{processor.inspect}"
                    end
                end
            end

            $LOG.debug("#{logical_path}: no directive found")
            return (@has_directive = false)
        end

        def copy?
            self.precompile?
            return !! @copy
        end
    end
end
end
