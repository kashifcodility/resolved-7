class UserImpersonationLog
    include DataMapper::Resource

    property :id, Serial

    property :admin_id, Integer, allow_nil: false
    belongs_to :admin, model: 'User', child_key: [ :admin_id ]

    property :user_id, Integer, allow_nil: false
    belongs_to :user, model: 'User', child_key: [ :user_id ]
    
    property :started_at, DateTime
    property :ended_at, DateTime, allow_nil: true

    def self.search_id_admin_user(query)
        return all() unless query
        return all(admin_id: query.to_i) |
               all(UserImpersonationLog.admin.first_name.like => "%#{query}%") |
               all(UserImpersonationLog.admin.last_name.like => "%#{query}%") |
               all(UserImpersonationLog.admin.email.like => "%#{query}%") |
               all(user_id: query.to_i) |
               all(UserImpersonationLog.user.first_name.like => "%#{query}%") |
               all(UserImpersonationLog.user.last_name.like => "%#{query}%") |
               all(UserImpersonationLog.user.email.like => "%#{query}%")
    end    
end
