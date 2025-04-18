# app/models/user.rb
# require "bcrypt"
class User < ApplicationRecord

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

         self.inheritance_column = "not_sti"
   # Enums
   enum active: { active: "Active", inactive: "Inactive" }

   enum user_type: { employee: "Employee", customer: "Customer", concierge: "Concierge" }       

     # Validations
  validates :first_name, length: { maximum: 20 }, format: { with: /\A\w+\z/, allow_nil: true }
  validates :last_name, length: { maximum: 20 }, format: { with: /\A\w+\z/, allow_nil: true }
  validates :email, length: { maximum: 50 }, uniqueness: true
  validates :stripe_customer_id, length: { maximum: 50 }, uniqueness: true, allow_nil: true
  validates :username, length: { maximum: 50 }, uniqueness: true, allow_nil: true
  # validates :password, length: { maximum: 255 }, allow_nil: true
  validates :mobile_username, length: { maximum: 45 }, allow_nil: true
  validates :mobile_password, length: { maximum: 70 }, allow_nil: true
  validates :profile_name, length: { maximum: 30 }, allow_nil: true
  validates :company_name, length: { maximum: 50 }, allow_nil: true
  validates :bio, length: { maximum: 140 }, allow_nil: true
  validates :telephone, length: { maximum: 20 }, allow_nil: true
  validates :mobile, length: { maximum: 20 }, allow_nil: true
  validates :occupation, length: { maximum: 64 }, allow_nil: true
  validates :hear_about, length: { maximum: 45 }, allow_nil: true
  validates :hear_about_other, length: { maximum: 45 }, allow_nil: true
  validates :logo_path, length: { maximum: 250 }, allow_nil: true
  validates :shipping_address_id, numericality: { only_integer: true, allow_nil: true }
  validates :billing_address_id, numericality: { only_integer: true, allow_nil: true }
  validates :membership_level_id, numericality: { only_integer: true, allow_nil: true }
  validates :site_id, numericality: { only_integer: true, allow_nil: true }

  has_many :credit_cards, dependent: :destroy
  has_many :user_roles
  has_many :roles, through: :user_roles
  belongs_to :default_credit_card, class_name: "CreditCard", optional: true
  has_many :order_queries
  has_many :delivery_appointments
  has_many :services
  has_many :concierge_quotes
  has_many :staging_insurance_proof
  has_many :products, foreign_key: :customer_id
  belongs_to :shipping_address, class_name: "Address", optional: true
  belongs_to :billing_address, class_name: "Address", optional: true
  belongs_to :membership_level, optional: true
  belongs_to :user_group, foreign_key: :group_id, optional: true
  has_many :user_membership_levels
  belongs_to :site, optional: true
  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id', optional: true
  has_one :cart
  has_many :reseller_licenses
  has_many :orders
  has_many :rooms
  has_many :wishlist, class_name: "UserWishlist", foreign_key: :user_id
  has_many :payments, class_name: "PaymentLog", foreign_key: :user_id
  has_many :commissions, foreign_key: :customer_id
  has_many :user_permission_assignments

  def formatted_telephone
    clean_phone = telephone.delete("^0-9")
    if clean_phone.size == 10
        telephone = "(%i) %i-%i" % [ clean_phone[-10..-8].to_i, clean_phone[-7..-5].to_i, clean_phone[-4..].to_i ] rescue telephone
    end
    telephone
  end
  def formatted_phone();  formatted_telephone;  end

  def formatted_mobile
      clean_phone = mobile.delete("^0-9")
      if clean_phone.size == 10
          mobile = "(%i) %i-%i" % [ clean_phone[-10..-8].to_i, clean_phone[-7..-5].to_i, clean_phone[-4..].to_i ] rescue mobile
      end
      mobile
  end

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
            model:     c
          })
      end
  end

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

  def reseller_license
    reseller_licenses.valid&.first
  end

  def favorites
    self.wishlist.map { |wl| wl.product }
  end

  def self.locate(account)
    # binding.pry
    User.where(active: "Active")
    .where(
      "email = :account OR username = :account OR mobile_username = :account",
      account: account
    ).first


    # (User.all(active: "Active") & (User.all(email: account) | User.all(username: account) | User.all(mobile_username: account))).first
  end


  #Password methods
  # def valid_password1?(password)
  #   password == mobile_password || BCrypt::Password.new(self.encrypted_password).is_password?(password)
  # rescue => error
  #   Rails.logger.debug "Password validation error: #{error.message}"
  #   false
  # end

  # def password=(new_password)
  #   super(BCrypt::Password.create(new_password))
  # end

  # def reset_code=(code)
  #   self.password = code
  # end

  # def reset_code
  #   password[0] == "$" ? nil : password
  # end

  def is_admin?
    user_type.capitalize == "Employee"
  end

  def logo_url
    # "https://#{S3_BUCKET_LOGOS}.s3-#{::SDN::AWS::S3::REGIONS[S3_BUCKET_LOGOS]}.amazonaws.com/#{logo_path}"
  end

  def years_since_created
    DateTime.current.year - join_date.year
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def full_name_and_email(glue: "", email_wrapper: [ " (", ")" ])
    fname = full_name.present? ? "#{full_name}#{glue}" : ""
    femail = email_wrapper.map { |wrapper| "#{wrapper}#{email}#{wrapper}" }.join
    fname + femail
  end

  def generate_username_from_name
    base_username = full_name.parameterize(separator: "_")
    taken_usernames = User.where("username LIKE ?", "#{base_username}%").pluck(:username)

    return base_username unless taken_usernames.include?(base_username)

    new_username = base_username.dup
    counter = 2

    while taken_usernames.include?(new_username)
      new_username = "#{base_username}#{counter}"
      counter += 1
    end

    new_username
  end

  def has_valid_credit_card?
    credit_cards.not_expired.any?
  end

  def valid_visible_credit_cards
    credit_cards.visible.not_expired.map do |c|
      OpenStruct.new({
        id: c.id,
        label: c.display_short(label_default: true),
        last_four: c.last_four,
        type: c.card_type.capitalize,
        exp_month: c.month,
        exp_year: c.year,
        default?: c.default?,
        model: c
      })
    end
  end

  def tax_exempt?
    reseller_license.present?
  end

  def tax_exempt_at?(date)
    reseller_licenses.valid.valid_before(date).valid_after(date)
  end

  def tax_exemption_expires_on
    reseller_license&.inactive_date
  end

  def tax_exemption_expired_on
    tax_exempt? ? nil : (reseller_licenses.approved.order(inactive_date: :desc).first&.inactive_date)
  end

  def self.search_id_name_phone_email(query)
    return all() unless query

    where("id = ? OR first_name LIKE ? OR last_name LIKE ? OR CONCAT(first_name, ' ', last_name) LIKE ? OR telephone LIKE ? OR mobile LIKE ?",
          query.to_i, "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
  end

  # ADMIN/EMPLOYEE SPECIFIC METHODS
  def permissions(site_id: nil)
    assignments = user_permission_assignments
    assignments = assignments.select { |upa| upa.site_id.in?(Array(site_id)) } if site_id
    return [] unless assignments.any?

    all_perms = UserPermission.with_children(id: assignments.pluck(:user_permission_id).uniq)

    # all_perms.map do |perm|
    #   OpenStruct.new(
    #     name: perm.name.to_sym,
    #     label: perm.label,
    #     sites: assignments.select { |a| a.user_permission_id.in?(perm.id, perm.parent_id) }.pluck(:site_id).uniq
    #   )
    # end
    # 
    #
    all_perms.map do |perm|
      OpenStruct.new(
        name: perm.name.to_sym,
        label: perm.label,
        sites: assignments.select { |a| [perm.id, perm.parent_id].include?(a.user_permission_id) }.pluck(:site_id).uniq
      )
    end  
  end

  def allowed?(*perms, site: nil)
    site = Array(site).map(&:to_i) if site
    singularized_perms = perms.map(&:to_s).map(&:pluralize).map(&:to_sym)
    pluralized_perms = perms.map(&:to_s).map(&:singularize).map(&:to_sym)
    permissions(site_id: site).any? { |p| p.name.in?(singularized_perms) || p.name.in?(pluralized_perms) }
  end

  alias_method :allowed_any?, :allowed?

  def allowed_sites(perm)
    # Array(permissions.find { |p| p.name.include?(perm.to_s.singularize.to_sym, perm.to_s.pluralize.to_sym) }&.sites)
    Array(permissions.find { |p| p.name.to_s.singularize.to_sym == perm || p.name.to_s.pluralize.to_sym == perm }&.sites)
  end

  # private

  # def hash_password
  #   self.password = BCrypt::Password.create(password)
  # end
end
