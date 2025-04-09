
class LegacyEditLog
    include DataMapper::Resource

    storage_names[:default] = "edit_log"
    
    property :id, Serial

    property :table_name, String, allow_nil: true
    property :table_id, Integer, allow_nil: true
    property :type, String, allow_nil: true
    property :reference, Text, allow_nil: false
    property :user_id, Integer, allow_nil: false
    belongs_to :user
    property :date, DateTime
    property :php_class_name, String, allow_nil: false

    def self.search_user_tableid_type_reference(query)
        return all() unless query
        return all(conditions: [ "CAST(user_id AS CHAR) LIKE '#{query.to_i}%'" ]) |
               all(conditions: [ "CAST(table_id AS CHAR) LIKE '#{query.to_i}%'" ]) |
               all(LegacyEditLog.user.first_name.like => "%#{query}%") |
               all(LegacyEditLog.user.last_name.like => "%#{query}%") |
               all(LegacyEditLog.user.email.like => "%#{query}%") |
               all(:type.like => "%#{query}%") |
               all(:reference.like => "%#{query}%")
    end
end
