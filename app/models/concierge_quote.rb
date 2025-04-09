require 'digest/md5'

# class ConciergeQuote
#     include ::DataMapper::Resource

#     property :id, Serial
#     #property :slug, String, unique: true, messages: { :is_unique => "Quote already exists." }
#     property :slug, RefCode, length: 8

#     # Agent's user account
#     property :user_id, Integer, index: true
#     belongs_to :user

#     property :homeowner_name, String
#     property :homeowner_email, String, format: :email_address
#     property :homeowner_phone, String
#     property :listing_address, String, length: 200
#     property :listing_price, Decimal, precision: 10, scale: 3
#     property :data, Json, default: {}, lazy: false

#     property :created_at, DateTime
#     property :updated_at, DateTime
#     property :emailed_at, DateTime, allow_nil: true
# end

class ConciergeQuote < ApplicationRecord
    belongs_to :user

    validates :slug, presence: true, uniqueness: { message: "Quote already exists." }
    validates :homeowner_email, format: { with: URI::MailTo::EMAIL_REGEXP }

    before_create :generate_slug

    private

    def generate_slug
        self.slug = SecureRandom.hex(4) # Generates an 8-character slug
    end
end
