class TransactionDetail
    include DataMapper::Resource

    property :id, Serial

    belongs_to :transaction

    property :details, Json, default: '{}'

    timestamps :at
end
