# class Invoice
#     include DataMapper::Resource

#     property :id, Serial

#     property :order_id, Integer, index: true
#     property :qbo_doc_number, String, length: 64    
#     property :status, String, length: 64
#     property :qbo_invoice_id, String, length: 64
#     property :from_date, DateTime, default: Time.now
#     property :created, DateTime, default: Time.now
#     property :edited, DateTime, default: Time.now
#     property :created_by, Integer
#     property :edited_by, Integer
#     property :created_with, String, default: 'PaymentProcessing'
#     property :edited_with, String, default: 'PaymentProcessing'
#     property :to_date, DateTime, default: Time.now
#     property :user_id, Integer, index: true
#     property :invoice_total, Float, default: 0.0
#     property :prorated_invoice_total, Float, default: 0.0
#     property :post_date, DateTime, default: Time.now
#     belongs_to :order
#     belongs_to :user
# end




class Invoice < ApplicationRecord
    belongs_to :order
    belongs_to :user

    validates :order_id, :user_id, presence: true
    validates :qbo_doc_number, :status, :qbo_invoice_id, length: { maximum: 64 }
    validates :invoice_total, :prorated_invoice_total, numericality: true

    # before_create :set_default_dates

    private

    def set_default_dates
        self.from_date ||= Time.now
        self.created ||= Time.now
        self.edited ||= Time.now
        self.to_date ||= Time.now
        self.post_date ||= Time.now
    end
end








