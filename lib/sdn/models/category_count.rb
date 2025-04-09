class CategoryCount
    include DataMapper::Resource

    property :id, Serial

    belongs_to :category

    property :count, Integer, default: 0
    property :updated_at, DateTime

end
