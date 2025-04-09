class CreditCard
    include DataMapper::Resource

    storage_names[:default] = 'credit_cards'

    property :id, Serial

    property :visible, Boolean, default: true 
    
    # At some point this field became the CC token
    property :info_key, String, length: 20
    alias_method :token, :info_key

    # At some point this field became the PNRef number
    property :customer_key, String, length: 20, allow_nil: true
    alias_method :pn_ref, :customer_key

    property :label, String, allow_nil: true
    property :type, String, length: 20
    property :last_four, String, length: 4
    property :month, String, length: 2
    property :year, String, length: 4

    property :created_at, DateTime, field: 'created'
    property :created_by, String, length: 40
    property :created_with, String, length: 50
    property :updated_at, DateTime, field: 'edited', allow_nil: true
    property :updated_by, String, field: 'edited_by', length: 40, allow_nil: true
    property :updated_with, String, field: 'edited_with', length: 50, allow_nil: true

    belongs_to :user

    property :address_id, Integer, allow_nil: true
    belongs_to :address

    def self.find_by_token(token)
        first(info_key: token)
    end
    
    def default!
        return false if expired?
        
        user.default_credit_card = self
        if user.save
            $LOG.info "Default credit card set: [card id: %i, user: %s]" % [ id, user.email ]
            return true
        else
            $LOG.error "Default credit card NOT set: [card id: %i, user: %s]" % [ id, user.email, user.errors.inspect ]
            return false
        end
    end
    
    # Is this card its owner's default
    def default?
        self == user.default_credit_card
    end
    
    def expired?
        "#{year}-#{month}-01".to_date.end_of_month < Date.today
    end

    def self.not_expired
        all(conditions: [ "LAST_DAY(DATE(CONCAT(year, '-', month, '-01'))) >= ?", Date.today ])
    end

    def self.visible
        all( visible: true )
    end

    # Shows label or formatted card type and number
    def display(label_default: false)
        return "%s %s ending in %i (exp %s/%s)%s" % [ label.present? ? "#{label} - " : '', type, last_four&.to_i, month.to_s, year.to_s, label_default && default? ? ' (default)' : '' ]
    end

    def display_short(label_default: false)
        return "%s %s - %s%s" % [ label.present? ? "#{label} - " : '', type, last_four, label_default && default? ? ' (default)' : '' ]
    end
    
    def disable!
        self.visible = false
        return self.save
    end

end
