class PaymentType
    include DataMapper::Resource

    storage_names[:default] = "payment_type"

    property :id, Serial

    property :type, String, length: 32
    property :description, String, length: 96

    has 0..n, :payments, model: 'PaymentLog'
end
