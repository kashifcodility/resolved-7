# class PayleapLog
#     include DataMapper::Resource

#     storage_names[:default] = "payleap_log"

#     property :id, Serial

#     property :action, String, length: 20
#     property :response, Text

#     property :created_at, DateTime, field: 'created'
#     property :created_by, String, length: 40, allow_nil: true

class PayleapLog < ApplicationRecord
    # Validations
    validates :action, length: { maximum: 20 }, allow_nil: true
    validates :response, presence: true, allow_nil: true
    validates :created_by, length: { maximum: 40 }, allow_nil: true

    def self.create_from_payleap_response(action, user_id, response)
        log = self.create(
            action: action,
            created_by: user_id,
            response: response.to_json
        )
        $LOG.info "PayLeap Log entry created (ID: %i, user: %i)" % [log.id, user_id]
    end

    def self.entry_count_since(time, user_id: nil)
        f = { :created_at.gte => time }
        f[:created_by] = user_id if user_id
        return self.count(f)
    end
end
