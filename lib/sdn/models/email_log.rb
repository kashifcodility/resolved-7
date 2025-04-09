class EmailLog
    include DataMapper::Resource

    storage_names[:default] = "email_log"

    property :id, Serial

    property :type, String, length: 40, allow_nil: true
    property :email_from, String, length: 50, allow_nil: true
    property :email_to, String, length: 200, allow_nil: true
    property :subject, String, length: 200, allow_nil: true
    property :rich_text, Text, allow_nil: true

    property :created_at, DateTime, field: 'created', allow_nil: true
    property :created_by, String, length: 40

    def self.create_from_mail_message(email, type:, created_by:0)
        unless email.is_a?(Mail::Message)
            $LOG.error "Email log NOT created: [class provided: %s, type: %s, created_by: %s] %s" % [ email.class, type, created_by, email.inspect ]
            return false
        end

        log = self.create(
            type:       type,
            email_from: email.from.join(','),
            email_to:   email.to.join(','),
            subject:    email.subject,
            rich_text:  email.to_s,
            created_by: created_by.to_s,
        )

        if log.saved?
            $LOG.info "Email log created: %i [type: %s]" % [ log.id, type ]
            return true
        else
            $LOG.error "Email log NOT created: [type: %s] %s" % [ type, log.errors.inspect ]
            return false
        end
    end
end
