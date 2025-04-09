# class Cms
#   include ::DataMapper::Resource

#   property :id, Serial

#   property :page, String, length: 255
#   property :title, String, length: 255

#   property :description, Text
#   property :type, String, length: 255
#   property :file_url, String, length: 500
# end

class Cms < ApplicationRecord
  self.table_name = 'cms'

  validates :page, length: { maximum: 255 }
  validates :title, length: { maximum: 255 }
  validates :file_url, length: { maximum: 500 }
end
