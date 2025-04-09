class Image
    include DataMapper::Resource

    storage_names[:default] = 'image_library'

    property :id, Serial

    belongs_to :user

    property :image, String, length: 250

    # Some of our past product data entry has some bullshit MS Word encoding. This fixes that.
    # We should ultimately do a cleanup of the database data, but this is the fix for now.
    def filename
        self.image.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "").force_encoding('UTF-8')
    end

    property :width, Integer, default: 0
    property :height, Integer, default: 0

    property :cached_url, String, allow_nil: true, length: 255
    property :cached_at, DateTime, allow_nil: true

    # Gets URL for image
    # TODO: Pull the bucket name to a config
    def url
        url = self.cached_url || cache_url($AWS.s3.public_url_for(self.filename, bucket: 'sdn-library')) rescue nil
    end

    # Cache the image URL
    def cache_url(url)
        self.cached_url = url
        self.cached_at = Time.zone.now

        if self.save
            $LOG.info "Image (%s) URL saved to cache: %s" % [ self.filename, url ] 
        else
            $LOG.error "Image (%s) URL not cached: %s | %s" % [ self.filename, url, self.errors.inspect ]
        end

        return url
    end
end
