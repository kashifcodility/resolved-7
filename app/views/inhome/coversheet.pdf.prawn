# 1. Creating function, where we can specify DOCUMENT SIZE: for document size pass [360, 504], where 360 and 504 are points (it would be 7x5 in inches):
prawn_document(page_size:[360, 504], page_layout: :landscape, ) do |pdf| 

    # 2. Creating background image:
    pdf.image @bg_image_path, :at => [-35.6, 324], :width => 504  

    # 3. QR Code:
    pdf.bounding_box([209,246 ], width: 259, height: 120, align: :center) do
        pdf.print_qr_code(@qrcode_url, dot: 2.1, align: :center, valign: :center)
    end

    # 4. First name box:
    pdf.bounding_box([209,93 ], width: 259, height: 24, align: :center) do
        # To see the box - uncomment line with the stroke:
        # pdf.stroke_bounds  
        pdf.font @font_semibold_path # everything below would be this font, if you want to change font apply pdf.font where needed (below you can see where I'm applying regular font)
        pdf.text @stager.first_name, size: 15, align: :center, valign: :center, :color => "03798d"
    end

    # 4. Last name box:
    pdf.bounding_box([209,68 ], width: 259, height: 24, align: :center) do
        pdf.text @stager.last_name, size: 15, align: :center, valign: :center, :color => "03798d"
    end

    # 5. Phone box:
    pdf.bounding_box([209,43 ], width: 259, height: 24, align: :center) do
        pdf.font @font_regular_path
        pdf.text @stager.phone, size: 15, align: :center, valign: :center, :color => "5f5b5a"
    end

    # 6. Email box:
    pdf.bounding_box([209,19 ], width: 259, height: 24, align: :center) do
        pdf.text @stager.email, size: 9, align: :center, valign: :center, :color => "5f5b5a"
    end

    # 7. Catalog-link box:
    pdf.bounding_box([209,-1 ], width: 259, height: 24, align: :center) do
        pdf.text %(<link href="#{@link_url}">#{@qrcode_url_display}</link>), :inline_format => true, size: 9, align: :center, valign: :center, :color => "03798d"
    end
		
end
