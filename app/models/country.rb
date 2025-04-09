# class Country
#     include DataMapper::Resource

#     property :id, Serial

#     property :country, String, length: 40
#     alias_method :name, :country

# end
class Country < ApplicationRecord
    self.table_name = 'countries'

    alias_attribute :name, :country
end
