require 'rqrcode'
require 'tempfile'

# class IhsCatalog
#     include DataMapper::Resource

#     storage_names[:default] = "ihs_orders_catalogs"

#     property :id, Serial

#     belongs_to :order

#     property :inhome_flyer,        Boolean,  default: false

#     property :partner_type,        String,   allow_nil: true
#     property :partner_name,        String,   allow_nil: true
#     property :partner_email,       String,   allow_nil: true
#     property :partner_telephone,   String,   allow_nil: true
#     property :partner_user_id,     Integer,  allow_nil: true

#     property :email_sent_for_sale, DateTime, allow_nil: true
#     property :email_sent_destage,  DateTime, allow_nil: true

#     property :qrcode_filename,     String,   allow_nil: true
    
#     timestamps :at


class IhsCatalog < ApplicationRecord
    # Associations
    belongs_to :order
    self.table_name = 'ihs_orders_catalogs'
  
    # Validations (optional, based on your business logic)
    # validates :partner_type, length: { maximum: 255 }, allow_nil: true
    # validates :partner_name, length: { maximum: 255 }, allow_nil: true
    # validates :partner_email, length: { maximum: 255 }, allow_nil: true
    # validates :partner_telephone, length: { maximum: 255 }, allow_nil: true
    # validates :qrcode_filename, length: { maximum: 255 }, allow_nil: true
  
    def qrcode_url
        $AWS.s3.public_url_for(qrcode_filename, bucket: 'sdn-ihs-qrcodes') rescue nil
    end
    
    # Generates QR code to catalog and saves it to S3
    def make_qrcode!
        # TODO: Where can this base url be found in configs?
        qr_url = 'https://www.r-e-solved.com' + Rails.application.routes.url_helpers.ihs_plp_path(id) + '/?utm_source=InHomeFlyer&utm_medium=Flyer&utm_campaign=InHomeSales'
        qr = RQRCode::QRCode.new(qr_url)

        png = qr.as_png(
            bit_depth: 1,
            border_modules: 4,
            color_mode: ChunkyPNG::COLOR_GRAYSCALE,
            color: 'black',
            file: nil,
            fill: 'white',
            module_px_size: 6,
            resize_exactly_to: false,
            resize_gte_to: false,
            size: 300
        )

        begin
            file = Tempfile.new([id.to_s, '.png'], encoding: 'ascii-8bit')
            file.write(png.to_s)
            file.close
            filename = "qr_catalog_#{id.to_s}.png"
            
            if $AWS.s3.upload(file.path, bucket: 'sdn-ihs-qrcodes', as: filename)
                self.qrcode_filename = filename
                if self.save
                    $LOG.info "ihs catalog updated with qr filename: [catalog: %i, file: %s]" % [ id, filename ]
                    return qrcode_url
                else
                    $LOG.debug "ihs catalog NOT updated with qr filename: [catalog: %i, file: %s]" % [ id, filename ]
                    return false
                end
            else
                $LOG.debug "ihs qr code NOT saved to S3: [catalog: %i, file: %s]" % [ id, filename ]
                return false
            end
        ensure
            file.close
            file.unlink
        end
    end
    
end
