class Site
    include DataMapper::Resource

    storage_names[:default] = "sites"

    property :id, Serial

    property :active, String, length: 10, allow_nil: true, default: "Active"

    property :site, String, length: 20
    alias_method :name, :site

    property :default_address_id, Integer, allow_nil: true
    belongs_to :address, child_key: [ :default_address_id ]

    property :default_contact_id, Integer, allow_nil: true
    property :receive_bin_id, Integer, allow_nil: true
    property :pick_bin_id, Integer, allow_nil: true
    property :will_call_bin_id, Integer, allow_nil: true

    property :type, String, length: 30, default: "Site"

    property :email, String, length: 100, allow_nil: true

    # NOTE: need to make sure these still work; underlying field for created is
    # TIMESTAMP in this case
    property :created_at, DateTime, field: 'created'
    property :updated_at, DateTime, field: 'edited'

    property :tax_authority_id, Integer, index: true
    belongs_to :tax_authority

    belongs_to :location, required: false

    has n, :users

    # TODO: Add this to the DB
    # Kirkland/Everett: Seattle
    # Phoenix: Phoenix
    def region
        self.site == 'Phoenix' ? self.site : 'Seattle'
    end

    def self.active
        all( active: 'Active' )
    end
end
