class Room
    include DataMapper::Resource

    property :id, Serial

    property :name, String, length: 64

    property :zone, StringEnum['NULL','Bathroom','Bedroom','Dining Room',
                                'Extra Room','Kitchen','Living Room','Office','Outside']
    
    property :token, String, length: 16

    has n, :order_lines
end