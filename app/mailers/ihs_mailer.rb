require 'open-uri'

class IhsMailer < ApplicationMailer
    default from: 're|SOLVED <support@r-e-solved.com>'
    default to:   'support@r-e-solved.com'

    # TODO: Add additional email address when customer isn't an internal account
    def send_receipt(customer, products, summary, receipt, billing_details, delivery_details)
        @products = products
        @summary = summary
        @receipt = receipt
        @billing = billing_details
        @delivery = delivery_details

        mail(to: billing_details.email, bcc: [ customer.email ], subject: "Receipt for Order #{@summary.ihs_order_id}", template_name: "receipt")
    end

    # Marketing email sent to stager and partner after order created
    def send_marketing_stage_for_sale(catalog_id:, stager_email:, partner_email: nil, qrcode_url: nil)
        @catalog_id = catalog_id
        
        to = [ stager_email ]
        to << partner_email if partner_email

        if qrcode_url
            begin
                attachments['qr_code.png'] = open(qrcode_url).read rescue nil
            rescue => e
                $LOG.debug "qr code NOT attached: [catalog: %i, url: %s] %s" % [ catalog_id, qrcode_url, e.message ]
            end
        end
        
	mail(to: to, cc: 'support@r-e-solved.com', subject: "Your Stage is For Sale", template_name: 'marketing_stage_for_sale')
    end

    # Marketing email sent to stager and partner after destage requested
    def send_marketing_destage(catalog_id:, stager_email:, partner_email: nil, qrcode_url: nil)
        @catalog_id = catalog_id
        
        to = [ stager_email ]
        to << partner_email if partner_email

        if qrcode_url
            begin
                attachments['qr_code.png'] = open(qrcode_url).read rescue nil
            rescue => e
                $LOG.debug "qr code NOT attached: [catalog: %i, url: %s] %s" % [ catalog_id, qrcode_url, e.message ]
            end
        end

	mail(to: to, cc: 'support@r-e-solved.com', subject: "Your Stage is For Sale", template_name: 'marketing_destage')        
    end

end
