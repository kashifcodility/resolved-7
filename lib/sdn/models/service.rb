class Service
    include DataMapper::Resource

    storage_names[:default] = 'services'

    property :id, Serial

    property :service, String, length: 30, allow_nil: true
    property :description, Text

    # NOTE: longer than User's (20)
    property :first_name, String, length: 30, format: ::SDN::DB::Property::NAMEREGEX
    property :last_name,  String, length: 30, format: ::SDN::DB::Property::NAMEREGEX

    property :email, String, length: 40
    property :website, String, length: 40

    property :company_name, String, length: 45
    property :office, String, length: 20
    property :fax, String, length: 20
    property :direct, String, length: 20
    property :mobile, String, length: 20

    property :active, String, length: 10, default: "Active"
    property :status, String, length: 40, default: "Open"

    # NOTE: Duplicates User's?  Also, logo_path(250) in User #WTF
    property :logo_path,        String, length: 50, lazy: true, allow_nil: true
    property :logo_width,       Integer, lazy: true, allow_nil: true
    property :logo_height,      Integer, lazy: true, allow_nil: true

    property :experience, Integer # WTF is this
    property :years_experience, Integer, default: 1

    property :licensed, String, length: 5, default: "No"
    property :bonded, String, length: 5, default: "No"

    property :created_at, DateTime, field: 'created'

    belongs_to :service_category
    belongs_to :address

    belongs_to :user

end
