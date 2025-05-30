class Subscription < ApplicationRecord
    self.table_name = "subscriptions"

    # storage_names[:default] = "subscriptions"

    # property :id, Serial
    # property :subscription_date,        DateTime
    # property :subscription_end_date,        DateTime
    # property :logo_width,       Integer, lazy: true, allow_nil: true
    # property :logo_height,      Integer, lazy: true, allow_nil: true

    # # TODO: document what these fields are
    # property :email_task,       String, length: 5, allow_nil: true
    # property :agree_to_terms,   Integer, allow_nil: true
    # property :pulled_credit,    Integer, default: 0
    # belongs_to :site
    # , model: 'Site', key: [:site_id]
    belongs_to :site
    # , model: 'User', key: [:user_id]
    # belongs_to :tier
    # , model: 'Tier', key: [:tier_id]
    
end
