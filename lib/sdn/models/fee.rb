class Fee
    include DataMapper::Resource

    property :id, Serial

    property :fee, String, length: 30
    property :recurring, String, length: 30
    property :type, String, length: 1
    property :amount, Decimal, precision: 10, scale: 2
    property :period, String, length: 10

    def self.self_rental_commission
        self.first(fee: 'Self Rental Commission').amount.to_d / 100
    end

    def self.damage_waiver
        self.first(fee: 'Damage Waiver').amount.to_d / 100
    end
end
