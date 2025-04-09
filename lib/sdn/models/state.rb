class State
    include DataMapper::Resource

    storage_names[:default] = "states"

    property :id, Serial

    property :abbreviation, String, length: 2, allow_nil: true
    property :state, String, length: 50, allow_nil: true

    # set blank to nil or false to exclude it
    def self.for_select(blank: '-- SELECT --')
        states = all(order: [ :state ]).map{ |s| [ s.state, s.abbreviation ] }
        states.unshift([ blank, nil ]) if blank
        return states
    end
end
