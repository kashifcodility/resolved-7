class MembershipLevel
    include DataMapper::Resource

    property :id, Serial

    property :level, String, length: 40, index: true

    # TODO: confirm this saves/stores proper precision
    # TODO: dm-migrations: BigDecimal -> DECIMAL(), but Float -> FLOAT.
    # BigDecimal is deprecated now, not clear what field type DM will
    # materialize from class Decimal .. Confirm.
    property :price, Decimal, precision: 10, scale: 2

    property :active, String, length: 10, default: "Active", index: true

    property :color, String, length: 7
    property :usage_level, Integer
    property :free_storage, String, length: 3, default: "No"
    property :display, String, length: 3, default: "Yes"

    property :subtitle, String, length: 250, allow_nil: true
    property :default_term_text, String, length: 50, allow_nil: true

    property :sequence, Integer, default: 1

    # FIXME: discount percent stored as integer?? WTFF??
    property :discount_percent, Integer, allow_nil: true

    has 1, :commission, model: 'MembershipLevelCommission'
end
