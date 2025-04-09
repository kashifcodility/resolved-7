require 'bcrypt'

class User
    include DataMapper::Resource

    const_def :S3_BUCKET_LOGOS, 'sdn-service-logos'

    property :id, Serial

    property :active, StringEnum["Active", "Inactive"], default: "Active"
    
    property :first_name,       String, length: 20, format: ::SDN::DB::Property::NAMEREGEX, allow_nil: true
    property :last_name,        String, length: 20, format: ::SDN::DB::Property::NAMEREGEX, allow_nil: true

    # NOTE: DB Schema default value is NULL, probably never should be allowed
    property :type, StringEnum["Employee", "Customer", "IDS", "Concierge"], default: "Customer"

    property :email,            String, length: 50, unique: true
    property :username,         String, length: 50, allow_nil: true, unique: true
    property :password,         String, length: 255

    # WTF are these?
    property :mobile_username,  String, length: 45, allow_nil: true
    property :mobile_password,  String, length: 70, allow_nil: true

    # TODO: WTF Is this?  Nuke?
    property :user_auth,        Text, allow_nil: true

    property :profile_name,     String, length: 30, allow_nil: true
    property :company_name,     String, length: 50,  lazy: true, allow_nil: true
    property :bio,              String, length: 140, lazy: true, allow_nil: true

    property :telephone,        String, length: 20, lazy: true, allow_nil: true
    property :mobile,           String, length: 20, lazy: true, allow_nil: true

    def formatted_telephone
        clean_phone = telephone.delete('^0-9')
        if clean_phone.size == 10
            telephone = "(%i) %i-%i" % [ clean_phone[-10..-8].to_i, clean_phone[-7..-5].to_i, clean_phone[-4..].to_i ] rescue telephone
        end
        return telephone
    end
    def formatted_phone();  formatted_telephone;  end

    def formatted_mobile
        clean_phone = mobile.delete('^0-9')
        if clean_phone.size == 10
            mobile = "(%i) %i-%i" % [ clean_phone[-10..-8].to_i, clean_phone[-7..-5].to_i, clean_phone[-4..].to_i ] rescue mobile
        end
        return mobile
    end
    
    property :picture,          String, length: 50, lazy: true, allow_nil: true
    property :occupation,       String, length: 64, lazy: true, allow_nil: true
    property :hear_about,       String, length: 45, lazy: true, allow_nil: true
    property :hear_about_other, String, length: 45, lazy: true, allow_nil: true

    # NOTE: This shit should be put in its own table
    property :logo_path,        String, length: 250, lazy: true, allow_nil: true
    property :logo_width,       Integer, lazy: true, allow_nil: true
    property :logo_height,      Integer, lazy: true, allow_nil: true

    # TODO: document what these fields are
    property :email_task,       String, length: 5, allow_nil: true
    property :agree_to_terms,   Integer, allow_nil: true
    property :pulled_credit,    Integer, default: 0
    property :join_date,        DateTime, default: ->(*) { Time.zone.now }
    alias_method :joined_at, :join_date
    property :sales_rep,        Integer, allow_nil: true # WTF is this?  a FK ref? or a flag?
    property :designer,         Integer, allow_nil: true  # WTF is this?  a FK ref? or a flag?
    property :source,           String, length: 15, allow_nil: true  # WTF is this?

    # Used by Warehouse1 to determine scope of access for different sites
    property :location_rights,  StringSet['ONE', 'ALL'], default: Set["ONE"]

    property :is_signup_complete, Boolean

    property :arrivy_customer_id, Integer, min: 0, max: 2**64-1, allow_nil: true
    property :arrivy_entity_id, Integer, min: 0, max: 2**64-1, allow_nil: true

    # User's default credit card
    property :credit_card_id, Integer, allow_nil: true
    belongs_to :default_credit_card, model: 'CreditCard', child_key: [:credit_card_id]
    has n, :credit_cards, model: 'CreditCard', child_key: [:user_id]

    def has_valid_credit_card?
        credit_cards.not_expired.any?
    end
    
    def valid_visible_credit_cards
        credit_cards.visible.not_expired.map do |c|
            OpenStruct.new({
               id:        c.id,
               label:     c.display_short(label_default: true),
               last_four: c.last_four,
               type:      c.type.capitalize,
               exp_month: c.month,
               exp_year:  c.year,
               default?:  c.default?,
               model:     c,
            })
        end
    end

    # Looked at table, mostly 1:1, but a few instances of 1:M, thus has n.
    has n, :services #, model: 'Service', child_key: [:user_id] # should work without spec

    has n, :concierge_quotes

    # Damage Waivers
    has n, :staging_insurance_proof
    def staging_insurance_proofs(); staging_insurance_proof; end
    
    def damage_waiver_exempt?
        staging_insurance_proofs.valid&.any?
    end

    def damage_waiver_expires_on
        staging_insurance_proofs.valid.first.expires_on rescue nil
    end

    def damage_waiver_expired_on
        staging_insurance_proofs.valid.any? ? nil : staging_insurance_proofs.expired.first.expires_on rescue nil
    end

    has n, :products, child_key: [:customer_id]

    # Some of these tables have user_id fields back -- need to confirm whether
    # they are reliably updated.  These references should have only been "has",
    # where the FK was on the remote table (not on User).
    property :shipping_address_id, Integer, allow_nil: true
    belongs_to :shipping_address, model: 'Address',         child_key: [:shipping_address_id]

    property :billing_address_id,  Integer, allow_nil: true
    belongs_to :billing_address,  model: 'Address',         child_key: [:billing_address_id]

    property :membership_level_id, Integer, allow_nil: true
    belongs_to :membership_level, model: 'MembershipLevel', child_key: [:membership_level_id]

    # History of membership level changes
    has n, :user_membership_level

    property :site_id, Integer, allow_nil: true, index: true
    belongs_to :site, model: 'Site', child_key: [:site_id]

    has 1, :cart

    has n, :reseller_licenses

    def reseller_license
        reseller_licenses.valid&.first
    end

    has 0..n, :orders

    has 0..n, :charge_accounts

    has 0..n, :wishlist, model: 'UserWishlist', child_key: [ :user_id ]

    has 0..n, :payments, model: 'PaymentLog', child_key: [ :user_id ]

    has 0..n, :commissions, child_key: [ :customer_id ]

    # Returns product models from the wishlist pivot table
    def favorites
        self.wishlist.map{ |wl| wl.product }
    end

    ## WTF/investigate
    #property :linked_to_id, Integer, allow_nil: true
    #property :membership_level, String, length: 30 # TODO: Nuke?

    # Find user based on the three different login methods (email, username, mobile_username)
    def self.locate(account)
        return (User.all(active: 'Active') & (User.all(email: account) | User.all(username: account) | User.all(mobile_username: account))).first
    end

    # Check given password against what's in the database.  We currently
    # authenticate in three scenarios, two of which use the same password field.
    # Unfortunately, mobile_password is currently stored in the clear...
    def valid_password?(password)
        begin 
            return password == mobile_password ||
                   ::BCrypt::Password.new(self.password.sub(/\A\$2y/, '$2a')).is_password?(password)
        rescue => error
            $LOG.debug "Password validation error: #{error.message}"
            return false
        end 
    end

    def password=(password)
        hashed_password = ::BCrypt::Password.create(password)
        attribute_set(:password, hashed_password)
    end

    # When resetting a password, the password field is populated with the reset code
    def reset_code=(code)
        attribute_set(:password, code)
    end

    def reset_code
        return self.password[0,1] == '$' ? nil : self.password
    end

    def is_admin?
        return type == "Employee"
    end

    # Generates full S3 URL for logo file name
    def logo_url
        return '//' + S3_BUCKET_LOGOS + '.s3-' + ::SDN::AWS::S3::REGIONS[S3_BUCKET_LOGOS] + '.amazonaws.com' + '/' + self.logo_path.to_s
    end

    def years_since_created
        return DateTime.zone.now.year - self.join_date.year
    end

    # Generates unique username from first + last
    # If dup detected: first-last2, first-last3, etc until no dup

    def full_name
        return "#{self.first_name} #{self.last_name}"
    end

    def full_name_and_email(glue: '', email_wrapper: [' (', ')'])
        fname = full_name + glue if full_name
        femail = ("%s%s%s" % [email_wrapper[0], email, email_wrapper[1]] rescue email)
        return fname + femail
    end

    def generate_username_from_name
        self.username = full_name.parameterize(separator: '_')
        taken = User.all(:username.like => self.username+'%', fields: [ :username ]).pluck(:username)

        unless taken.include? self.username
            return self.username
        end

        self.username += 2.to_s

        while taken.include? self.username
            self.username.succ!
        end

        return self.username
    end

    # Exempt if valid reseller license exists
    def tax_exempt?
        reseller_license.present?
    end

    # Was the user tax exempt at a specific time?
    def tax_exempt_at?(date)
        reseller_licenses.valid.valid_before(date).valid_after(date)
    end

    def tax_exemption_expires_on
        reseller_license&.inactive_date
    end

    def tax_exemption_expired_on
        tax_exempt? ? nil : (reseller_licenses.approved.all( order: [ :inactive_date.desc ] ).first.inactive_date rescue nil)
    end

    def self.search_id_name_phone_email(query)
        return all() unless query
        return all(id: query.to_i) |
               all(:first_name.like => "%#{query}%") |
               all(:last_name.like => "%#{query}%") |
               all(conditions: [ "CONCAT(`first_name`, ' ', `last_name`) LIKE ?", "%#{query}%" ]) |
               all(:telephone.like => "%#{query}%") |
               all(:mobile.like => "%#{query}%") |
               all(:email.like => "%#{query}%")
    end

    #
    # ADMIN/EMPLOYEE SPECIFIC METHODS
    #

    has n, :user_permission_assignments

    # Gets user's permissions (including child permissions) optionally filtered by site ID
    def permissions(site_id: nil)
        assignments = user_permission_assignments
        assignments = assignments.select { |upa| upa.site_id.among?(Array(site_id)) } if site_id
        return [] unless assignments.any?    
       
        all_perms = UserPermission.with_children(id: assignments.pluck(:user_permission_id).uniq)

        return all_perms.map do |perm|
            OpenStruct.new(
                name:  perm.name.to_sym,
                label: perm.label,
                sites: assignments.select{ |a| a.user_permission_id.among?(perm.id, perm.parent_id) }.pluck(:site_id).uniq,
            )
        end        
    end

    def allowed?(*perms, site: nil)
        site = Array(site).map(&:to_i) if site
        singularized_perms = perms.map(&:to_s).map(&:pluralize).map(&:to_sym)
        pluralized_perms = perms.map(&:to_s).map(&:singularize).map(&:to_sym)
        return !!permissions(site_id: site).find{ |p| p.name.among?(singularized_perms) || p.name.among?(pluralized_perms) }
    end
    alias_method :allowed_any?, :allowed?

    def allowed_sites(perm)
        Array(permissions.find{ |p| p.name.among?(perm.to_s.singularize.to_sym, perm.to_s.pluralize.to_sym) }&.sites)
    end
    
end
