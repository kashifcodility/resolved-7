# class DeliveryAppointment
#     include DataMapper::Resource

#     property :id, Serial
    
#     property :special_instructions, Text, allow_nil: true
#     property :schedule_date, String, length: 60
#     property :project_name, String, length: 220
#     property :client_name, String, length: 220
#     property :contact_info, String, length: 250
#     property :delivery, String, length: 150
#     property :approx_budget, String, length: 100
#     property :created_at, DateTime
#     property :updated_at, DateTime
#     property :status,     Boolean,  default: false

#     belongs_to :user

    
# end


class DeliveryAppointment < ApplicationRecord
    self.table_name = 'delivery_appointments'

    # Associations
    belongs_to :user

    # Validations (if needed)
    validates :schedule_date, length: { maximum: 60 }
    validates :project_name, length: { maximum: 220 }
    validates :client_name, length: { maximum: 220 }
    validates :contact_info, length: { maximum: 250 }
    validates :delivery, length: { maximum: 150 }
    validates :approx_budget, length: { maximum: 100 }

    # Default values
    attribute :status, :boolean, default: false
end
