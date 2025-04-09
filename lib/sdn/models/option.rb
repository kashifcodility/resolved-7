class Option
    include ::DataMapper::Resource

    storage_names[:default] = 'yuxi_options'

    property :id, Serial

    property :tag, StringEnum['COLOR','MATERIAL','FABRIC','WOOD','METAL',
                                'SOFA_SIZE','TABLE_SIZE','BED_SIZE'] 

    property :label, String, length: 50

end
