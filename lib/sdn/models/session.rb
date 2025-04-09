require 'sdn/session_store'

# Basically a "dumb" class; other than serialization logic, all other logic is
# inside of common/ruby/session_store.rb.

class Session
    include ::DataMapper::Resource
    include ::SDN::SessionStore::BSON

    # Should name it sessions, but some stupid bullshit is already in our way.
    storage_names[:default] = 'full_sessions'

    property :id,         Serial
    property :session_id, String,   unique_index: true
    property :data,       Json,     required: true, lazy: false, auto_validation: false, default: '{}'
    property :created_at, DateTime, required: false, index: true
    property :updated_at, DateTime, required: false, index: true

    def data=(new_data)
        attr = bson_serialize(new_data)
        attribute_set(:data, attr)
    end

    def data
        bson_deserialize(attribute_get(:data))
    end

    # Gets the last updated session datetime
    # Serves the purpose of determining a signed in user's last activity timestamp
    def self.last_updated_for_user(user_id)
        return $DB.select("SELECT updated_at FROM full_sessions WHERE data->'$.user_id' = #{user_id} ORDER BY updated_at DESC LIMIT 1").first rescue nil
    end

    def self.site_id_for_user(user_id)
        return $DB.select("SELECT data->'$.site_id' AS site_id FROM full_sessions WHERE data->'$.user_id' = #{user_id} ORDER BY updated_at DESC LIMIT 1").first rescue nil
    end
    
end

const_def :SDNSESSION, ::Session
