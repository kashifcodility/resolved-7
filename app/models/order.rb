# class Order
#     include DataMapper::Resource

#     # Thresholds for order freeze dates (Rental orders only)
#     # TODO: Move these to database config
#     const_def :FREEZE_DELIVERY_TIMEOFDAY, { hour: 00, min: 00 } # 4:30PM for delivery
#     const_def :FREEZE_DELIVERY_DAYS,      2 # 2 days prior on every non-Monday day for delivery
#     const_def :FREEZE_PICKUP_TIMEOFDAY,   { hour: 00, min: 00 } # 4:30PM for pickup
#     const_def :FREEZE_PICKUP_DAYS,        2 # 2 days prior on every non-Monday day for pickup
#     const_def :FREEZE_WDAY_EXCLUSIONS,    [ 6, 0 ] # Days of week to exclude (Sun-Sat starting at index 0)
#     const_def :FREEZE_DATE_EXCLUSIONS,    [ # Specific dates to exclude (holidays) YYYY-MM-DD
#                   '2022-01-12', '2022-01-13', '2022-01-14', '2022-01-24', '2022-01-25', '2022-05-30', '2022-07-04', '2022-09-05', '2022-11-24',
#                   '2022-11-25', '2022-12-23', '2022-12-26', '2023-01-01', ]

#     # Threshold for order rent accrual start (Rental orders only)
#     const_def :ACCRUAL_STARTS_DAYS, 7 # 7 days after order creation date or delivery date

#     # An order can be destaged 5 business days after today (Rental orders only)
#     const_def :DESTAGE_AFTER_DAYS, 5


#     property :id, Serial
#     has 0..n, :order_queries
#     has 1..n, :order_status_signatures
#     has 1..n, :order_lines
#     has 0..n, :order_fees
#     has 0..n, :extra_fees
#     has 0..n, :product_piece_locations, table_name: 'orders', child_key: [ :table_id ]
#     property :tax_authority_id, Integer, allow_nil: true
#     belongs_to :tax_authority
#     has 1, :ihs_catalog
#     has 1, :order_log
#     has 0..n, :project_walk_through
#     has 0..n, :invoices
#     # property :pickedup, DateTime
#     property :rush_order, Boolean, default: false
#     property :tax_location_id, String, allow_nil: true # NOTE: THIS IS NOT A MODEL - it's the stateAssignedNo, SOME of the time.
    
#     property :project_name, String, length: 40, allow_nil: true
#     property :dwelling, String, length: 40, allow_nil: true
#     property :parking, String, length: 40, allow_nil: true
#     property :levels, String, length: 40, allow_nil: true
#     property :delivery_special_considerations, Text, allow_nil: true
#     property :reference, String, length: 40, allow_nil: true
#     property :show_in_orders, String, length: 5, default: "Yes"
    
#     property :finalized, String, length: 5, default: "No"
#     property :service, String, length: 20, index: true, allow_nil: true
#     property :note, Text
#     has 1, :hold, 'OrderHold'
#     property :status, String, length: 20
#     property :changed, String, length: 5, default: "no"
#     belongs_to :site
#     property :type, String, length: 20, index: true
#     property :service_confirmed, Boolean, default: false
#     property :user_id, Integer, index: true
#     belongs_to :user
#     property :address_id, Integer, allow_nil: true
#     belongs_to :address
#     alias_method :shipping_address, :address
#     property :bill_to_address_id, Integer, allow_nil: true
#     belongs_to :billing_address, model: 'Address', child_key: [ :bill_to_address_id ]
#  #
#     # Order Dates
#     #

#     property :ordered_date, DateTime, default: ->(*) { Time.zone.now }
#     alias_method :ordered_on, :ordered_date

#     # Scheduled ship date
#     property :due_date, DateTime
#     alias_method :due_on, :due_date
#     alias_method :shipping_at, :due_date
#     alias_method :shipping_scheduled_at, :due_date
#     property :delivery_date, DateTime # This date can't be trusted as when the order was delivered
#     alias_method :delivery_on, :delivery_date
#     property :destage_date, DateTime
#     alias_method :destage_on, :destage_date
#     alias_method :destaging_at, :destage_date
#     property :complete_date, DateTime
#     alias_method :complete_on, :complete_date

#     property :shipping_date, DateTime
#     alias_method :shipping_on, :shipping_date
#     property :first_name, String, length: 20, allow_nil: true, lazy: true
#     property :last_name, String, length: 20, allow_nil: true, lazy: true
#     property :company, String, length: 40, allow_nil: true, lazy: true
#     property :address1, String, length: 40, allow_nil: true, lazy: true
#     property :address2, String, length: 40, allow_nil: true, lazy: true
#     property :city, String, length: 40, allow_nil: true, lazy: true
#     property :state, String, length: 2, allow_nil: true, lazy: true
#     property :zip, String, length: 10, allow_nil: true, lazy: true
#     property :country, String, length: 20, allow_nil: true, lazy: true
#     property :phone, String, length: 10, allow_nil: true, lazy: true
#     property :bill_to_first_name, String, length: 20, allow_nil: true, lazy: true
#     property :bill_to_last_name, String, length: 20, allow_nil: true, lazy: true
#     property :bill_to_company, String, length: 40, allow_nil: true, lazy: true
#     property :bill_to_address1, String, length: 40, allow_nil: true, lazy: true
#     property :bill_to_address2, String, length: 40, allow_nil: true, lazy: true
#     property :bill_to_city, String, length: 40, allow_nil: true, lazy: true
#     property :bill_to_state, String, length: 2, allow_nil: true, lazy: true
#     property :bill_to_zip, String, length: 10, allow_nil: true, lazy: true
#     property :bill_to_country, String, length: 20, allow_nil: true, lazy: true
#     property :bill_to_phone, String, length: 10, allow_nil: true, lazy: true

#     #
#     # Payment Details
#     #

#     property :credit_card_id, Integer, allow_nil: true
#     belongs_to :credit_card, model: 'CreditCard', child_key: [ :credit_card_id ]
    #
    # Order Type
    #


class Order < ApplicationRecord
    # Thresholds for order freeze dates (Rental orders only)
    FREEZE_DELIVERY_TIMEOFDAY = { hour: 0, min: 0 } # 4:30PM for delivery
    FREEZE_DELIVERY_DAYS = 2  # 2 days prior on every non-Monday day for delivery
    FREEZE_PICKUP_TIMEOFDAY = { hour: 0, min: 0 } # 4:30PM for pickup
    FREEZE_PICKUP_DAYS = 2     # 2 days prior on every non-Monday day for pickup
    FREEZE_WDAY_EXCLUSIONS = [6, 0]  # Days of week to exclude (Sun-Sat starting at index 0)
    FREEZE_DATE_EXCLUSIONS = [
        '2022-01-12', '2022-01-13', '2022-01-14', '2022-01-24', '2022-01-25', '2022-05-30', '2022-07-04', '2022-09-05', '2022-11-24',
        '2022-11-25', '2022-12-23', '2022-12-26', '2023-01-01'
    ]
    
    # Threshold for order rent accrual start (Rental orders only)
    ACCRUAL_STARTS_DAYS = 7  # 7 days after order creation date or delivery date
    
    # An order can be destaged 5 business days after today (Rental orders only)
    DESTAGE_AFTER_DAYS = 5
    
    # Relationships (ActiveRecord version)
    has_many :order_queries
    has_many :order_status_signatures
    has_many :order_lines
    has_many :order_fees
    has_many :extra_fees
    has_many :product_piece_locations, foreign_key: :table_id
    belongs_to :tax_authority, optional: true
    has_one :ihs_catalog
    has_one :order_log
    has_many :project_walk_through
    has_many :invoices
    has_one :hold, class_name: 'OrderHold'
    belongs_to :site
    belongs_to :user
    belongs_to :address
    belongs_to :billing_address, class_name: 'Address', foreign_key: :bill_to_address_id, optional: true
    belongs_to :credit_card, optional: true
    
    # Order Dates
    validates :ordered_date, presence: true
    
    # Aliases (ActiveRecord uses these natively)
    alias_attribute :ordered_on, :ordered_date
    alias_attribute :due_on, :due_date
    alias_attribute :shipping_at, :due_date
    alias_attribute :shipping_scheduled_at, :due_date
    alias_attribute :delivery_on, :delivery_date
    alias_attribute :destage_on, :destage_date
    alias_attribute :destaging_at, :destage_date
    alias_attribute :complete_on, :complete_date
    alias_attribute :shipping_on, :shipping_date
    
    # Validations
    validates :service, length: { maximum: 20 }, allow_nil: true
    validates :note, presence: true, allow_nil: true
    validates :first_name, length: { maximum: 20 }, allow_nil: true
    validates :last_name, length: { maximum: 20 }, allow_nil: true
    validates :company, length: { maximum: 40 }, allow_nil: true
    validates :address1, length: { maximum: 40 }, allow_nil: true
    validates :address2, length: { maximum: 40 }, allow_nil: true
    validates :city, length: { maximum: 40 }, allow_nil: true
    validates :state, length: { maximum: 2 }, allow_nil: true
    validates :zip, length: { maximum: 10 }, allow_nil: true
    validates :country, length: { maximum: 20 }, allow_nil: true
    validates :phone, length: { maximum: 10 }, allow_nil: true
    
    # Callbacks
    before_save :set_default_values
    
         


    def transactions()  Transaction.where(order: [ :id.asc ]).for_order(id)  end
    def on_hold?()  hold&.on_hold == 'HOLD'  end
    def finalized?() finalized =~ /Yes/i end
    def show_in_orders?() show_in_orders =~ /Yes/i end
    def rental?()                order_type == 'Rental'    end
    def sales?()                 order_type == 'Sales'     end
    def self.rentals()           where(order_type: 'Rental') end
    def self.sales()             where(order_type: 'Sales')  end
    def self.renting_rentals()   where(order_type: 'Rental', status: 'Renting')  end # TODO: Replace useage of this with .renting.rentals


    #
    # Order Statuses
    #

    
    def open?()     status == 'Open'           end
    def cancel?()     status == 'Cancel'       end
    def renting?()  status == 'Renting'        end
    def complete?() status == 'Complete'       end
    def void?()     status.downcase == 'void'  end
    def can_be_reopened?()   status.among?('Pulled', 'InTransit', 'Renting') end
    def self.not_voided()  where(conditions: ["LOWER(status) != 'void'"])  end
    def self.open()        where(status: 'Open')     end
    def self.renting()     where(status: 'Renting')  end
    def self.active()      where(:status.not => [ 'Complete', 'Void' ])  end

    def cancellable_by_customer?(at: Time.zone.now)
        open? && rental? && frozen?(at: at)
    end

    def can_add_products?
        !frozen? && rental?
    end
    
    def self.default_rush_order_fee
        100.00
    end
    
    def self.default_shipping_fee
         100.00
    end

    # Checks if order is frozen relative to specific time
    def frozen?(at: Time.zone.now)
        $LOG.debug "timezone set to UTC (OrderKeyDates#frozen?)" unless at&.to_time&.zone != 'UTC'
        return false unless freezes_at
        freezes_at <= at
    end

    def accruing_rent?(at: Time.zone.now)
        rent_accrual_starts_on <= at
    end

    def destaged?
        return nil unless rental?
        return false if renting?
        return order_lines.product_lines.empty?{ |pl| pl.detail.returned? }
    end

    # Checks if this order is able to be destaged
    # Order must be Renting, have a destage_date set, and supplied date is after #soonest_destage_date.
    def can_be_destaged?(date: nil)
        return false unless status == 'Renting' and destage_date.nil?
        return false if date and date.to_date < Order.soonest_destage_date
        return true
    end

    # Marks an order as changed
    # Example scenario is when an item on an open order is voided.
    def changed!(changed_by:nil)
        self.changed = 'Yes'

        if self.save
            $LOG.info "Order marked as changed: %i" % [ self.id, changed_by&.email ]
            return true
        else
            $LOG.error "Order NOT marked as changed: %i" % [ self.id, changed_by&.email, self.errors.inspect ]
            return false
        end
    end


    #
    # Warehouse Location
    #


    def self.for_site(site_id)  where(site_id: site_id.to_i)  end


    #
    # Shipping Service
    #

    
    def delivery?()     service == 'Company' end
    def pickup?()       service == 'Self'    end
    alias_method :willcall?, :pickup?
    def appointment_type
        if delivery? && destage_date.nil?
            return 'Delivery'
        elsif delivery? && destage_date.present?
            return 'Destage'
        elsif pickup?
            return 'Will Call'
        end
    end
    def delivery_method()  pickup? ? :pickup : :delivery  end
    
    def shipped?
        shipped_at.present? || order_lines.shipped.not_voided.any?
    end
    def delivered?()  Order.ship_date(id).present?  end # FIXME: Should not be the same as #shipped?


    #
    # Order Creator/Customer
    #

   
    def self.belongs_to_user?(user)
        self.customer_id == user&.id || user.to_i
    end


    #
    # Order Addresses
    #

    

    def last_credit_card_charged
        user.credit_cards.first(last_four: last_credit_card_charge.cc_last_four)
    end

    def last_credit_card_charge
        Transaction.where(order: [ :id.desc ], limit: 1).for_order(id).credit_card.first
    end


   

    # Actual ship date
    def shipped_at
        (order_lines.shipped.first.detail.shipped_at rescue nil) || Order.ship_date(id)
    end

    
    def completed?()  complete_date.present?  end # How does this combine with status Complete?
    

    def destaged_at
        return nil unless destaged?
        return (order_lines.product_lines.sort{ |a,b| b.detail.returned_at <=> a.detail.returned_at }.first.returned_at rescue nil)
    end


    # Static method for getting earliest requestable destage date
    # This is currently used for blocking off days on the destage request form's calendar
    def self.soonest_destage_date(from: Time.zone.today)
        DESTAGE_AFTER_DAYS.business_days.after(from)
    end

    # TODO: Delete me
    def self.modification_pickup_date_after
        Time.zone.today
    end

    # TODO: Delete me
    def self.modification_delivery_date_after
        BusinessTime::Config.beginning_of_workday = BusinessTime::ParsedTime.parse('12:00am')
        BusinessTime::Config.end_of_workday = BusinessTime::ParsedTime.parse('11:59pm')
	return 1.business_days.after(Time.previous_business_day(Time.zone.today))
    end

    # Determines next renewal billing date
    # TODO: Add param type check exceptions
    def self.next_rental_renewal_date(ordered_at, delivered_at=nil, today=nil)
        today ||= Date.today

        ordered_plus_7 = ordered_at + 7.days

        # Sets renewal start date at delivery date, or 7 days after order - whichever is sooner
        renewal_start_date = (delivered_at.nil? || ordered_plus_7 > delivered_at) ? ordered_plus_7 : delivered_at

        # Sets next renewal date as renewal start + 37 days, or every 7 days after that until it's greater than today
        next_renewal_date = renewal_start_date + 37.days
        if next_renewal_date <= today
            until next_renewal_date > today
                next_renewal_date += 7.days
            end
        end

        return next_renewal_date
    end

    # The date/time an order freezes
    #
    # A frozen order is an order that can not be modified in any way by the customer. This includes
    # adding products, voiding lines, or cancelling the order.
    #
    # NOTE: "frozen" is synonymous with "lockout" or "locked date" in other parts of the app.
    # NOTE: This only applies to open rental orders.
    #
    # This is calculated by starting with the order schedule date and then stepping back in time
    # one day at a time. It will continue stepping back in time as long as the selected date or day
    # of week is excluded from the specified rules (FREEZE_DATE_EXCLUSIONS and FREEZE_WDAY_EXCLUSIONS),
    # and there aren't FREEZE_DELIVERY_DAYS/FREEZE_PICKUP_DAYS (dependent on shipping method) total valid days.
    #
    # For example (assuming configured for two days before scheduled delivery):
    #  1) Tuesday, June 1     Order scheduled for delivery
    #  2) Monday, May 31      Holiday - subtract a day - 0 valid days before scheduled date
    #  3) Sunday, May 30      Weekend - subtract a day - 0 valid days before scheduled date
    #  4) Saturday, May 29    Weekend - subtract a day - 0 valid days before scheduled date
    #  5) Friday, May 28      Weekday - subtract a day - 1 valid days before scheduled date
    #  6) Thursday, May 27    Weekday - subtract a day - 2 valid days before scheduled date  <- this is the freeze date
    #
    # Current business rules enforced by this method:
    #
    #  Scheduled Day           Delivery Freeze         Pickup Freeze
    #   Monday                  Thursday at 4:30pm      Thursday at 4:30pm
    #   Tuesday                 Sunday at 4:30pm        Sunday at 4:30pm
    #   Wednesday               Monday at 4:30pm        Monday at 4:30pm
    #   Thursday                Tuesday at 4:30pm       Tuesday at 4:30pm
    #   Friday                  Wednesday at 4:30pm     Wednesday at 4:30pm
    #   Tuesday (Mon Holiday)   Thursday at 4:30pm      Thursday at 4:30pm
    #   (no pickups/deliveries on weekends)
    #
    def freezes_at
        $LOG.debug "order due_date not set when trying to get freezes_at time: [order: #{id}]" unless shipping_scheduled_at
        return nil unless rental? && shipping_scheduled_at.present?

        if delivery?
            fd  = FREEZE_DELIVERY_DAYS
            tod = FREEZE_DELIVERY_TIMEOFDAY
        else
            fd  = FREEZE_PICKUP_DAYS
            tod = FREEZE_PICKUP_TIMEOFDAY
        end

        # Creates freezes at starting point to begin stepping back from, with proper time/zone
        date = shipping_scheduled_at.to_time.asctime.in_time_zone.change(tod)

        biz_days = 0
        while biz_days < fd
            unless FREEZE_DATE_EXCLUSIONS.include?(date) || FREEZE_WDAY_EXCLUSIONS.include?(date.wday)
                biz_days += 1
            end
            # biz_days += 1 unless date.to_date.among?(FREEZE_DATE_EXCLUSIONS.map{ |d| d.to_date }) or date.to_date.wday.among?(FREEZE_WDAY_EXCLUSIONS)
            date -= 1.day
        end

        

        return date
    end

    # The date an order starts accruing rent
    #
    # NOTE: Threshold is inclusive (eg: Jan 1 will start accruing Jan 7)
    #
    # Current business rules for when rent accrual starts:
    #
    #  - Order type is Rental
    #  - Whichever date occurs first:
    #     1) Seven days after creation date
    #     2) Delivery (due) date
    #
    def rent_accrual_starts_on
        return nil unless rental?
        threshold = ordered_on&.to_date + ACCRUAL_STARTS_DAYS.days
        return threshold unless shipping_at.present?
        return threshold <= shipping_at&.to_date ? threshold : shipping_at&.to_date
    end

    def first_billed_on
        return shipped_at || shipping_at
    end

    def first_billing_cycle_ends_on
        return first_billed_on + 29.days # effectively 30 days (including delivery day)
    end





    # TODO: Below this line needs to be organized/refactored still.


    # NOTE: Chunk of shit presumed to only be relevant on old ass orders --
    # normalized into the Address table now.
    
    # Why is this necessary?
    def next_rental_renewal
        return nil unless order_type == 'Rental' && status.among?('Open','Pulled','InTransit','Renting')

        return OpenStruct.new(
            date:   Order.next_rental_renewal_date(ordered_on, Order.ship_date(id)),
            totals: next_rental_renewal_totals,
        )
    end

    # Re-calculates damage waiver
    # TODO: This is duplicate logic from within the Cart lib - this is the right place for it
    def refresh_damage_waiver!
        
        return true if user.damage_waiver_exempt?

        dw_line = self.order_lines.damage_waiver.first
        product_lines = self.order_lines.product_lines
    
        old_waiver = dw_line.base_price
        new_waiver = (product_lines.pluck(:base_price).sum * Fee.damage_waiver).to_d.ceil(2)
        dw_line.base_price = new_waiver
        dw_line.price = new_waiver

        if dw_line.save
            $LOG.info "Damage waiver refreshed for order: %i [dw line: %i, old: %.2f, new: %.2f]" % [ self.id, dw_line.id, old_waiver, new_waiver ]
            return true
        else
            $LOG.error "Damage waiver NOT refreshed for order: %i [dw line: %i, old: %.2f, new: %.2f] %s" % [ self.id, dw_line.id, old_waiver, new_waiver, dw_line.errors.inspect ]
            return false
        end
    end


    #
    # Order Status Checks
    #



    ##
    ## Order Monetary Calculations
    ##
    ## TODO: Make method naming more consistent
    ##


    # Sum of price for product specific order lines
    def product_subtotal
        order_lines.product_lines.pluck(:base_price).sum
    end

    # Sum of price for product specific order lines
    def product_total
        order_lines.product_lines.pluck(:price).sum
    end

    def non_product_subtotal
        order_lines.non_product_lines.pluck(:base_price).sum
    end

    def non_product_total
        order_lines.non_product_lines.pluck(:price).sum
    end

    def non_product_tax
        non_product_total - non_product_subtotal
    end

    def product_tax
        product_total - product_subtotal
    end

    def total_tax
        (product_total - product_subtotal) + (non_product_total - non_product_subtotal)
    end

    def tax_rate
        tax_authority&.total_rate
    end

    def damage_waiver_subtotal
        order_lines.damage_waiver.not_voided.pluck(:price).sum
    end

    # Sum of unvoided order lines
    # NOTE: does include tax
    def total
        order_lines&.not_voided&.pluck(:price)&.compact&.sum
    end

    # Sum of voided order lines
    def void_lines_total
        order_lines.voided.pluck(:price).sum
    end

    def void_lines_subtotal
        order_lines.voided.pluck(:base_price).sum
    end

    def void_lines_tax
        void_lines_total - void_lines_subtotal
    end

    # Calculates the next renewal amount to be billed
    # TODO: Verify if this is being used anymore
    def next_rental_renewal_totals
        products_subtotal = order_lines.product_lines.pluck(:base_price).sum / 30 * 7
        products_total    = order_lines.product_lines.pluck(:price).sum / 30 * 7
        tax               = products_total - products_subtotal
        damage_waiver     = products_subtotal * 0.04
        total             = products_subtotal + tax + damage_waiver

        return { subtotal: products_subtotal, tax: tax, damage_waiver: damage_waiver, total: total }
    end


    ##
    ## Order Searching
    ##


    # Broadly searches orders and ancillary attributes
    def self.search_id_user_project_address(query)
        return where() unless query
        return where(:conditions                 => [ "CAST(id AS CHAR) LIKE '#{query.to_i}%'" ]) |
               where(Order.user.first_name.like  => "%#{query}%") |
               where(Order.user.last_name.like   => "%#{query}%") |
               where(Order.user.email.like       => "%#{query}%") |
               where(:project_name.like          => "%#{query}%") |
               where(Order.address.address1.like => "%#{query}%") |
               where(Order.address.city.like     => "%#{query}%") |
               where(Order.address.zipcode.like  => "#{query}%") |
               where(Order.site.site => query)
    end

    # Gets sibling orders
    #
    # This currently finds siblings by looking at:
    #   - Orders with matching address ID, matching address first line, or matching project name
    #   - Must belong to same customer
    #   - Must be a Rental or Sales order
    #   - Must not have a status of Void or Open
    #
    # TODO: Make a separate table that relates similar orders. This current method has proven unreliable.
    #
    # `only_currently_renting` arg will filter out all orders not renting
    # `include_source` arg will include the order being searched against
    def sibling_rental_orders(only_currently_renting: true, include_source: false)
        query = %{
            SELECT orders.id FROM orders
            LEFT JOIN addresses ON addresses.id = orders.address_id
            WHERE (
                orders.address_id = #{address_id}
                OR addresses.address1 = ?
            )
            AND orders.user_id = #{user_id}
            AND orders.id != #{id}
            AND orders.order_type IN ('Rental', 'Sales')
            AND orders.status NOT IN ('Void', 'Open')
        }.squish

        order_ids = repository.adapter.select(query, address.address1)

        orders = only_currently_renting ? Order.where(id: order_ids).renting_rentals : Order.where(id: order_ids)
        orders << self if include_source

        return orders
    end


    ##
    ## Legacy SQL
    ##


    # Gets the shipped date for an order
    # TODO: Fix needless subquery... this was copied from legacy?
    def self.ship_date(order_id)
        result = $DB.select <<-FOO
            SELECT
                (SELECT ll.created
                    FROM product_piece_locations AS ll
                    WHERE ll.table_name = 'orders'
                        AND ll.table_id = o.id
                        AND ll.log_type = 'Shipped'
                        AND ll.void    != 'yes'
                    ORDER BY ll.id DESC
                    LIMIT 1
                ) AS ship_date
            FROM orders AS o
            WHERE o.id = #{order_id}
            LIMIT 1
        FOO
        return result&.first
    end

    # Gets the earliest ship date for an order
    # NOTE: This is in anticipation of be able do multiple deliveries for a single order at different times.
    def self.initial_ship_date(order_id)
        result = $DB.select <<-FOO
            SELECT ll.created
            FROM product_piece_locations AS ll
            WHERE ll.table_name = 'orders'
                AND ll.table_id = #{order_id.to_i}
                AND ll.log_type = 'Shipped'
                AND ll.void    != 'yes'
            ORDER BY ll.id ASC
            LIMIT 1
        FOO
        return result&.first
    end

    # Gets the date the order was placed
    def self.on_order_date(order_id)
        result = $DB.select <<-FOO
            SELECT ll.created
            FROM product_piece_locations AS ll
            WHERE ll.table_name = 'orders'
                AND ll.table_id = #{order_id.to_i}
                AND ll.log_type = 'OnOrder'
                AND ll.void    != 'yes'
            ORDER BY ll.id DESC
            LIMIT 1
        FOO
        return result&.first
    end

    # Gets orders for a user
    # Status maps to `status` column
    def self.orders_for_user(user_id, status='all')
        $DB.select <<-FOO
            SELECT o.id, o.order_type, o.status, o.changed, ordered_date, due_date, ppl.created AS created, COUNT(l.product_id) AS order_lines,
                    (SELECT ll.created FROM product_piece_locations ll WHERE ll.table_name = 'orders' AND ll.table_id = o.id AND ll.log_type = 'Shipped' AND ll.void != 'yes' LIMIT 0,1) AS ship_date,
                    (SELECT DATE_FORMAT(lll.created,'%m/%d/%Y') FROM product_piece_locations lll WHERE lll.table_name = 'orders' AND lll.table_id = o.id AND lll.log_type = 'Returned' AND lll.void != 'yes' LIMIT 0,1) AS return_date, o.project_name
            FROM orders o
            LEFT JOIN order_lines l ON l.order_id = o.id AND l.void != 'yes'
            LEFT JOIN products p ON p.id = l.product_id
            LEFT JOIN users u ON u.id = o.user_id
            LEFT JOIN addresses a ON a.id = o.address_id
            LEFT JOIN addresses ba ON ba.id = o.bill_to_address_id
            LEFT JOIN product_pieces AS pp ON pp.id IN (SELECT product_pieces.id FROM product_pieces WHERE l.product_id = product_pieces.product_id)
            LEFT JOIN product_piece_locations AS ppl ON ( ppl.table_id = l.order_id AND ppl.product_piece_id = pp.id )
            WHERE o.show_in_orders = 'Yes'
                AND ( '#{status}' = 'Open&Renting' AND o.status IN ('Open','Pulled','InTransit','Renting')
                OR ( '#{status}' = 'all')
                OR ( '#{status}' = 'Returned' AND o.status = 'Complete')
                OR ( '#{status}' = 'OnOrder' AND o.status IN ('Open','Pulled','InTransit'))
                OR o.status = '#{status}')
                AND ('' IS NULL OR '' = '' OR o.id = '' OR o.project_name LIKE CONCAT('','%'))
                AND u.id = '#{user_id}'
            GROUP BY o.id order by o.id desc
        FOO
    end

    # Order details
    def self.rental_order_details(user, order, status: 'NULL', sort_by: 'o.ordered_date DESC')
        user_id = user.id rescue user.to_i
        order_id = order.id rescue order.to_i

        rooms = Room.all(fields: [:id, :name], order: [:token, :name])
        room_ids = rooms.pluck('id').join(',')
        room_names = rooms.pluck('name').join(',')

        results = $DB.select <<-FOO
            SELECT p.id, p.product, l.image as main_image,l.width AS main_image_width, l.height AS main_image_height, p.width, p.height, p.depth,
                p.description, p.product_restrictions, c.category, p.rent_per_month, p.rent_per_day, p.sale_price, p.serial,
                p.available, p.stored, p.storage_price, p.income,p.for_sale,p.for_rent,p.reserved,p.box,
                p.quantity,DATE_FORMAT(loc.created,'%b %e %Y') AS last_log_date, o.order_type AS order_type,
                IFNULL((SELECT att.attribute FROM product_attributes patt
                        LEFT JOIN attributes att ON att.id = patt.attribute_id
                        WHERE att.attribute_type <> 'Bumped and Bruised' AND att.attribute_type <> 'Vignettes'
                            AND patt.product_id = p.id
                        GROUP BY patt.product_id), 'Uncategorized') as furniture_attribute,
                concat(CASE WHEN LENGTH(IFNULL(p.rent_per_month,'')) = 0 THEN '' ELSE CONCAT('$',ROUND(p.rent_per_month/30,2),'/day | ') END,
                CASE WHEN LENGTH(IFNULL(p.rent_per_month,'')) = 0 THEN '' ELSE CONCAT('$',p.rent_per_month,'/Mo.') END) as formatted_rent,
                CASE WHEN loc.log_type = 'Available' THEN 'Available'
                        WHEN o.order_type = 'Sales' OR o.order_type = 'Rental' THEN
                        CASE WHEN loc.void = 'yes' THEN 'Cancelled'
                                WHEN loc.log_type = 'OnOrder' THEN 'On Order'
                                WHEN loc.log_type = 'Pulled' AND o.service = 'Company' THEN 'Processed For Shipping'
                                WHEN loc.log_type = 'Pulled' AND o.service = 'Self' THEN 'Ready For Pick-up'
                                WHEN loc.log_type = 'InTransit' THEN 'Shipping'
                                WHEN loc.log_type = 'Shipped' AND o.service = 'Company' THEN 'Delivered'
                                WHEN loc.log_type = 'Shipped' AND o.service = 'Self' THEN 'Picked-up'
                                WHEN loc.log_type = 'Returned' THEN 'Returned'
                                ELSE 'Unknown' END
                        WHEN o.order_type = 'Return' THEN 'Available'
                        WHEN o.order_type = 'TransferToShop' THEN 'Available'
                        ELSE 'Unavailable' END as status,
                loc2.void, loc.log_type, IF(ol.void = 'no',DATE_FORMAT(loc.created,'%b %e %Y'),DATE_FORMAT(ol.voided_date,'%b %e %Y')) AS log_date,
                ol.base_price, o2.id AS current_order_id, ol.id AS orderLineId, ol.room_id AS room, '#{room_ids}' AS roomIds, '#{room_names}' AS roomNames
            FROM products p
            LEFT JOIN categories c on c.id = p.category_id
            LEFT JOIN product_images i ON i.product_id = p.id AND i.image_order = 1
            LEFT JOIN image_library l ON l.id = i.image_id
            INNER JOIN product_pieces pc ON pc.product_id = p.id
            INNER JOIN product_piece_locations loc ON loc.table_name = 'orders' AND loc.product_piece_id = pc.id AND (#{order_id} IS NULL OR loc.table_id = #{order_id})
                    AND loc.id = (SELECT MAX(id) FROM product_piece_locations l2 WHERE l2.product_piece_id = pc.id AND table_name = 'orders' AND (#{order_id} IS NULL OR table_id = #{order_id}) AND log_status = 'Posted' AND ((('#{status}' IS NULL OR '#{status}' != 'Void') AND l2.void != 'yes') OR l2.void = 'yes'))
            LEFT JOIN orders o ON loc.table_id = o.id
            LEFT JOIN order_lines ol ON ol.order_id = o.id AND ol.product_id = p.id
            LEFT JOIN product_piece_locations loc2 ON loc2.table_name = 'orders' AND loc.product_piece_id = pc.id
                AND loc2.id = (SELECT MAX(id) FROM product_piece_locations l2 WHERE l2.product_piece_id = pc.id AND table_name = 'orders' AND log_status = 'Posted' AND (((#{order_id} IS NULL OR #{order_id} != 'Void') AND l2.void != 'yes') OR l2.void = 'yes'))
            LEFT JOIN orders o2 ON o2.id = loc2.table_id
            WHERE o.user_id = #{user_id}
            AND ol.void != 'yes'
            AND (#{order_id} IS NULL OR o.id = #{order_id})
            AND p.product_type != 'NonStock'
            GROUP BY p.id
        FOO
    end

    private
    
    def set_default_values
        self.ordered_date ||= Time.zone.now
        self.finalized ||= 'No'
        self.changed ||= 'no'
        self.show_in_orders ||= 'Yes'
    end 

end
