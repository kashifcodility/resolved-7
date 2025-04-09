class MembershipLevelCommission
    include DataMapper::Resource

    property :id, Serial

    belongs_to :membership_level

    property :base_commission, Decimal, precision: 5, scale: 3, allow_nil: true
    property :promo_commission, Decimal, precision: 5, scale: 3, allow_nil: true

    property :promo_days_active, Integer, allow_nil: true

    belongs_to :created_by, model: 'User', child_key: [ :created_by ], allow_nil: true
    belongs_to :updated_by, model: 'User', child_key: [ :updated_by ], allow_nil: true
    property :created_at, DateTime, allow_nil: true
    property :updated_at, DateTime, allow_nil: true
end
