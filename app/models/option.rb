# class Option
#     include ::DataMapper::Resource

#     storage_names[:default] = 'yuxi_options'

#     property :id, Serial

#     property :tag, StringEnum['COLOR','MATERIAL','FABRIC','WOOD','METAL',
#                                 'SOFA_SIZE','TABLE_SIZE','BED_SIZE', 'SITE',"SIZE"]

#     property :label, String, length: 50

# end


class Option < ApplicationRecord
     self.table_name = 'yuxi_options'   
    enum tag: { COLOR: 'COLOR', MATERIAL: 'MATERIAL', FABRIC: 'FABRIC', WOOD: 'WOOD', METAL: 'METAL',
                SOFA_SIZE: 'SOFA_SIZE', TABLE_SIZE: 'TABLE_SIZE', BED_SIZE: 'BED_SIZE', SITE: 'SITE', SIZE: 'SIZE' }

    validates :label, length: { maximum: 200 }

end
