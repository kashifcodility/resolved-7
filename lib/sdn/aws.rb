# Singleton class to contain our credentials and wrap the AWS-specific class
# libraries.
#
# Author: Jordan Ritter <jpr5@sdninc.co>
#
#
# Docs
#
#     https://docs.aws.amazon.com/en_pv/sdk-for-ruby/v3/developer-guide/
#     https://docs.aws.amazon.com/sdk-for-ruby/v3/api/
#
#
# Conventions
#
#   - "Name" tag of S3 objects is the basename of the file we upload.  Thus it's
#     incumbent on us to make sure the filenames are always unique / won't
#     collide.  Easier to do this and be compatible with how things are aleady
#     done, rather than work out more complicated conventions and have to store
#     extra information on the server side to track/reference them.
#
#   - S3 Bucket Names - TODO: enumerate what we have and conventionally, what
#     types of data belong where.
#
#
# Considerations
#
# (1) AWS Envariables vs. the SDN configuration
#
#     We configure ourselves the same way all the other system components do,
#     for consistency sake -- via YAML.  However, we know AWS' libraries will
#     auto-pickup certain envariables and use those as configuration.  This
#     could lead to problems.
#
#     Consider the case where this library is being used in a script; it's
#     entirely possible the user could forget envariables are set as they move
#     about their business, and would most likely expect our configuration to
#     win.
#
#     As well, SDN's configuration uses services across multiple regions; in a
#     concurrent/threaded scenario, different services need different configs.
#     The envariable approach is insufficient for this.
#
#     So, we unset the envariables for the process when this library is
#     initialized.
#
#
# TODO
#   - figure out why wire tracing doesn't emit to our Logger (as it's supposed to)
#

require 'aws-sdk-s3'
require 'aws-sdk-ses'

require 'sdn/log'
require 'sdn/config'


class SDN::AWS < Module
    include ::Singleton

    module Exceptions
        class Error               < RuntimeError; end
        class ConfigError         < Error;        end
        class InvalidConfig       < ConfigError;  end
        class S3Error             < Error;        end
        class UnreadableFile      < S3Error;      end
        class UnwriteableLocation < S3Error;      end
    end
    include Exceptions

    attr_accessor :config

    const_def :CONFIG_FILE, "config/aws.yml"

    def initialize
        ENV['AWS_SDK_CONFIG_OPT_OUT'] = "1"
        ENV.delete('AWS_ACCESS_KEY_ID')
        ENV.delete('AWS_SECRET_ACCESS_KEY')
        ENV.delete('AWS_REGION')
    end

    # CONFIG:
    # {
    #   common: { access_key_id: ..., secret_access_key: ..., region: ... },
    #   s3: { access_key_id: ..., secret_access_key: ..., region: ... },      # overrides
    #   ses: { access_key_id: ..., secret_access_key: ..., region: ... },     # overrides
    # }
    def configure(file = nil)
        file ||= SDNROOT / CONFIG_FILE

        self.config = ::SDN::Config.load(file)

        common = config.delete(:common)

        # merge common config, add our logger and reform config for AWS v2
        [ :s3, :ses ].each do |k|
            config[k].deep_merge!(common)
            config[k][:logger] = $LOG
            config[k][:credentials] = Aws::Credentials.new(
                config[k].delete(:access_key_id),
                config[k].delete(:secret_access_key),
            )
        end

        # validate minimum keys necessary
        unless [ :s3, :ses ].all? do |k|
                   [ :credentials, :region ].all? do |_k|
                       config[k].key?(_k)
                   end
               end
            raise InvalidConfig, "config [#{config.inspect}] missing required parameters"
        end

        $LOG.info "AWS: configured for S3:#{config[:s3][:credentials].access_key_id}@#{config[:s3][:region]}, SMTP:#{config[:ses][:username]} -> SES:#{config[:ses][:credentials].access_key_id}@#{config[:ses][:region]}"

        return true
    end

    def tracing?
        return config.keys.any? { |k| config[k][:http_wire_trace] }
    end

    def tracing=(onoff)
        config.keys.each { |k| config[k][:http_wire_trace] = onoff }
        return onoff
    end

    def s3(conf = {})
        @s3 ||= S3.new(config[:s3].merge(conf))
    end

    def ses(conf = {})
        @ses ||= SES.new(config[:ses].merge(conf))
    end

    def reset
        @s3 = @ses = nil
        return self
    end

    #
    # Examples:
    #
    #    $AWS.s3.upload("/path/to/somefile.txt", bucket: "sdnfoo")
    #    $AWS.s3.upload("/path/to/somefile.txt", bucket: "sdnfoo", as:"subdir/somefile.txt")
    #    $AWS.s3.download("somefile.txt", bucket: "sdnfoo", to: "/path/to/somefile.txt")
    #
    #    $AWS.s3.object("subdir/somefile.txt", bucket: "sdnfoo").exists?
    #    $AWS.s3.object("subdir/somefile.txt", bucket: "sdnfoo").delete
    #
    #    $AWS.s3.public_url_for("somefile.txt", bucket: "sdnfoo")                # subject to ACLs
    #    $AWS.s3.signed_url_for("somefile.txt", bucket: "sdnfoo")                # works regardless
    #    $AWS.s3.signed_url_for("somefile.txt", bucket: "sdnfoo", method: :head) # HEAD only
    #    $AWS.s3.url_for("somefile.txt", bucket: "sdnfoo")                       # signed = DEFAULT
    #
    #    $AWS.s3.bucket("sdnfoo")                             # => Aws::S3::Bucket
    #    $AWS.s3.object("somefile.txt", bucket: "sdnfoo")     # => Aws::S3::Object
    #    $AWS.s3.resource                                     # => Aws::S3::Resource
    #
    # Useful docs:
    #
    #    https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Object.html
    #    https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Bucket.html
    #    https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Resource.html
    #
    class S3
        include ::SDN::AWS::Exceptions

        attr_accessor :config, :resource

        # FIXME: we use separate buckets instead of subdirectories. :-(((
        # NOTE: most of these don't appear to be used - can we nuke?
        # TODO: migrate to bucket:"sdn", object:"profile/.." | object:"print/" (EVENTUALLY)
        # NOTE: PHP code generated PDFs locally to enable user access -> put in AWS + signed_urls
        #
        # sdn-users 58# (us-west-1)
        # sdn-thumb 17856# (us-east-1) - PHP: printing (receipt, invoice, tearsheet) ACL: PUBLIC
        # sdn-store-promotions 10# (us-west-1) - ACL: PUBLIC
        # sdn-store EMPTY (us-west-1)
        # sdn-service-logos 793# (us-west-1)
        # sdn-product-photos EMPTY (us-west-1)
        # sdn-library 23713# (us-west-1)  - PHP: this is the default bucket
        # sdn-front-page 55# (us-west-1)
        # sdn-csv EMPTY (us-west-2)
        # sdn-content 11# (us-west-1)
        # sdn-ads 19# (us-west-1)
        const_def :REGIONS, {
                      'sdn-users' => 'us-west-1',
                      'sdn-thumb' => 'us-east-1',
                      'sdn-store-promotions' => 'us-west-1',
                      'sdn-store' => 'us-west-1',
                      'sdn-service-logos' => 'us-west-1',
                      'sdn-product-photos' => 'us-west-1',
                      'sdn-library' => 'us-west-1',
                      'sdn-front-page' => 'us-west-1',
                      'sdn-csv' => 'us-west-2',
                      'sdn-content' => 'us-west-1',
                      'sdn-showcase' => 'us-west-2',
                      'sdn-ads' => 'us-west-1',
                      'sdnfoo' => 'us-west-2',
                      'private-sdn-backups' => 'us-west-2',
                      'sdn-ihs-qrcodes' => 'us-west-2',
                  }

        # TODO: establish complete list of blob types we store + target bucket
        const_def :BUCKETS, {
                      :profile_image => 'sdn-...',
                      # ...
                  }

        def initialize(config = {})
            @config = config
            @region = config[:region] # convenience shortcut
        end

        def resource(conf = nil)
            reset && @region = conf[:region] if conf[:region] != @region rescue false
            @resource ||= Aws::S3::Resource.new(config.merge(conf))
        end

        def region(r)
            resource(region: r)
            return self
        end

        def bucket(name)
            return resource(region: region_for(name)).bucket(name)
        end

        def objects(bucket:)
            return bucket(bucket).objects
        end

        def object(name, bucket:)
            return bucket(bucket).object(name)
        end

        def upload(file, bucket:, metadata: {}, as:nil)
            raise UnreadableFile.new("can't read file #{file}") unless File.readable?(file)
            return object(as || File.basename(file), bucket: bucket).upload_file(file, metadata: metadata, acl: 'public-read')
        end

        def download(name, bucket:, to:)
            raise UnwritableLocation.new("unable to write to #{to}") unless File.writable?(File.dirname(to))
            return object(name, bucket: bucket).get(response_target: to)
        end

        def copy(original, bucket:, to:)
            object(original, bucket:bucket).copy_to(key: to, bucket: bucket)
        end

        def delete(name, bucket:)
            object(name, bucket:bucket).delete
        end

        def rename(original, bucket:, to:)
            copy(original, bucket:bucket, to:to)
            delete(original, bucket:bucket)
        end

        def public_url_for(name, bucket:)
            return object(name, bucket: bucket).public_url
        end

        def signed_url_for(name, bucket:, method: :get, opts: {})
            return object(name, bucket: bucket).presigned_url(method, opts)
        end

        # Use #signed_url_for by default
        alias_method :url_for, :signed_url_for

        def reset
            @resource = nil
            return self
        end

        def tracing?
            return config[:http_wire_trace] || false
        end

        def tracing=(onoff)
            config[:http_wire_trace] = onoff
            return onoff
        end

        private

        def region_for(bucket)
            return REGIONS[bucket.to_s] || @region
        end

        # Meant to aid (later) use of #upload(file, type:), #download(file,
        # type:, to:) so we rely on "data types" for determining where data
        # should go, e.g. #upload("jpr5-profile.jpg", :profile_image)
        def bucket_for(type)
            return BUCKETS[type.to_sym]
        end
    end

    #
    # Convenience class for manual use.  Intention is to integrate with Rails'
    # ActionMailer, which will give us templates and other sugar that tastes
    # Great.
    #
    class SES
        include ::SDN::AWS::Exceptions

        attr_accessor :config, :client

        def initialize(config = {})
            @config = config
        end

        def client
            @client ||= Aws::SES::Client.new(config)
        end

        # ... TODO: complete standard methods as needed

        def reset
            @client = nil
            return self
        end

        def tracing?
            return config[:http_wire_trace] || false
        end

        def tracing=(onoff)
            config[:http_wire_trace] = onoff
            return onoff
        end
    end

end

$AWS = ::SDN::AWS.instance
$AWS.send(:include, ::SDN::AWS::Exceptions)
