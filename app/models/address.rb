class Address < ApplicationRecord
  self.table_name = 'addresses'

  # Set default values
  after_initialize :set_defaults, if: :new_record?

  # ActiveRecord already defines an id column by default
  # For active column, use an enum to define status values
  enum active: { active: 'Active', inactive: 'Inactive' }, _default: :active

  # Validations to ensure data consistency
  validates :name, length: { maximum: 40 }, allow_nil: true
  validates :company, length: { maximum: 40 }, allow_nil: true
  validates :address1, length: { maximum: 100 }, allow_nil: true
  validates :address2, length: { maximum: 100 }, allow_nil: true
  validates :city, length: { maximum: 40 }, allow_nil: true
  validates :state, length: { maximum: 2 }, allow_nil: true
  validates :zipcode, length: { maximum: 10 }, allow_nil: true
  validates :phone, length: { maximum: 15 }, allow_nil: true
  validates :mobile_phone, length: { maximum: 15 }, allow_nil: true

  # Default country_id to 1 (US)
  belongs_to :country, default: -> { Country.find_by(id: 1) }

  # Geolocation attributes
  validates :latitude, numericality: true, allow_nil: true
  validates :longitude, numericality: true, allow_nil: true

  def first_name()  name.split(/\s/).first rescue name    end
  def last_name()   name.split(/\s/)[1..].join rescue ''  end
    
  def full_address
      return "%s%s %s, %s. %s" % [ address1, (address2 ? " #{address2}" : ''), city, state, zipcode ]
  end

  def formatted_phone
      clean_phone = phone&.delete('^0-9')
      if clean_phone&.size == 10
          phone = "(%i) %i-%i" % [ clean_phone[-10..-8].to_i, clean_phone[-7..-5].to_i, clean_phone[-4..].to_i ] rescue phone
      end 
      return phone
  end  

  # WTF fields? Maybe not needed depending on your app
  attr_accessor :table_name, :table_id
end

