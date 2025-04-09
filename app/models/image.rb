# class Image
#     include DataMapper::Resource

#     storage_names[:default] = 'image_library'

#     property :id, Serial

#     belongs_to :user

#     property :image, String, length: 250

#     property :width, Integer, default: 0
#     property :height, Integer, default: 0

#     property :cached_url, String, allow_nil: true, length: 255
#     property :cached_at, DateTime, allow_nil: true

class Image < ApplicationRecord
    self.table_name = 'image_library'
    # Associations
    belongs_to :user
  
    # Validations (optional, based on your business logic)
    validates :image, presence: true, length: { maximum: 250 }
  
    # Optional: Cache validation or custom logic
    validates :cached_url, length: { maximum: 255 }, allow_nil: true
    
    def filename
        self.image.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "").force_encoding('UTF-8')
    end

    # Gets URL for image
    # TODO: Pull the bucket name to a config
    def url
        if self.filename&.include?('neoasisinteriors.com')
            url = self.cached_url || cache_url(self.filename) rescue nil
        else
            url = self.cached_url || cache_url($AWS.s3.public_url_for(self.filename, bucket: 'sdn-library')) rescue nil
        end
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
