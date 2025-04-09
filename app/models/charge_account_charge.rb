# class ChargeAccountCharge
#     include ::DataMapper::Resource

#     property :id, Serial

#     belongs_to :charge_account

#     property :type, String, length: 20
#     property :status, String, length: 10
#     property :amount, Decimal, precision: 10, scale: 2
#     property :table_name, String, length: 50
#     property :table_id, Integer

#     property :created_at, DateTime, field: "created"
#     property :created_by, String, field: "created_by", length: 40
#     property :created_with, String, length: 50
#     property :updated_at, DateTime, field: "edited"
#     property :updated_by, String, field: "edited_by", length: 40
#     property :updated_with, String, field: "edited_with", length: 50

# end


class ChargeAccountCharge < ApplicationRecord
    belongs_to :charge_account

    validates :type, length: { maximum: 20 }
    validates :status, length: { maximum: 10 }
    validates :amount, numericality: { precision: 10, scale: 2 }
    validates :table_name, length: { maximum: 50 }
    validates :table_id, numericality: { only_integer: true }
    validates :created_by, length: { maximum: 40 }
    validates :created_with, length: { maximum: 50 }
    validates :updated_by, length: { maximum: 40 }
    validates :updated_with, length: { maximum: 50 }

    self.table_name = 'charge_account_charges'

    before_create :set_created_at
    before_update :set_updated_at

    private

    def set_created_at
        self.created_at = DateTime.now
    end

    def set_updated_at
        self.updated_at = DateTime.now
    end
end
