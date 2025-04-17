require 'nokogiri'
require 'httparty'
require 'net/http'
require 'builder'


class DispatchTrackService

  def self.import_order(order)

    uri = URI(ENV['DISPATCHTRACK_URL'])
    request = Net::HTTP::Post.new(uri)
    
    request.set_form_data({
      'code' => ENV['DISPATCHTRACK_CODE'],
      'api_key' => ENV['API_KEY'],
      'data' => build_order_xml(order)
    })


    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    response = http.request(request)
    if response.code == '200'
      puts "Order successfully imported: #{order[:number]}"
    else
      puts "Error importing order: #{response.body}"
    end
  end

  def self.build_order_xml(order_data)
    xml = Builder::XmlMarkup.new(:indent => 2)

    xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    xml.service_orders do
      xml.service_order do
        xml.number order_data[:order_number]
       
        xml.service_type order_data[:service_type]
        
        
        xml.customer do
          xml.customer_id order_data[:customer][:id]
          xml.first_name order_data[:customer][:first_name]
          xml.last_name order_data[:customer][:last_name]
          xml.email order_data[:customer][:email]
          xml.phone1 order_data[:customer][:phone1]
          xml.phone2 order_data[:customer][:phone2]
          xml.phone3 order_data[:customer][:phone3]
          xml.address1 order_data[:customer][:address1]
          xml.address2 order_data[:customer][:address2]
          xml.city order_data[:customer][:city]
          xml.state order_data[:customer][:state]
          xml.zip order_data[:customer][:zip]
          xml.latitude order_data[:customer][:latitude]
          xml.longitude order_data[:customer][:longitude]
          xml.preferred_contact_method order_data[:customer][:preferred_contact_method]
        end
        
        xml.delivery_date order_data[:delivery_date]
        xml.request_delivery_date order_data[:request_delivery_date]

        xml.items do
          order_data[:items].each do |item|
            xml.item do
              xml.sale_sequence item[:sale_sequence]
              xml.item_id item[:item_id]
              xml.serial_number item[:serial_number]
              xml.description { xml.cdata! item[:description] }
              xml.line_item_notes item[:line_item_notes]
              xml.number item[:barcode_number]
              xml.quantity item[:quantity]
              xml.location item[:location]
              xml.cube item[:cube]
              xml.setup_time item[:setup_time]
              xml.weight item[:weight]
              xml.price item[:price]
              xml.countable item[:countable]
              xml.store_code item[:store_code]
            end
          end
        end


        xml.additional_fields do
          xml.project_name order_data[:additional_fields][:project_name]
          xml.order_link order_data[:additional_fields][:order_link]
        end  



      end
    end

    xml.target!    
  end
end

