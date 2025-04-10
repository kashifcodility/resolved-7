class Fee < ApplicationRecord
    # include DataMapper::Resource

    # property :id, Serial

    # property :fee, String, length: 30
    # property :recurring, String, length: 30
    # property :type, String, length: 1
    # property :amount, Decimal, precision: 10, scale: 2
    # property :period, String, length: 10

    def self.self_rental_commission
        self.where(fee: 'Self Rental Commission')&.first.amount.to_d / 100
    end

    def self.damage_waiver
        self.where(fee: 'Damage Waiver')&.first.amount.to_d / 100
    end
end
