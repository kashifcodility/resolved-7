# class TransactionDetail
#     include DataMapper::Resource

#     property :id, Serial

#     belongs_to :transaction

#     property :details, Json, default: '{}'

#     timestamps :at
# end


class TransactionDetail < ApplicationRecord
    belongs_to :transaction

    serialize :details, JSON

    # ActiveRecord automatically manages created_at and updated_at timestamps
end
