require 'csv'
class ProjectEstimationsController < ApplicationController
    def estimations_pdf

      @project_data = {
        client_name: "Adam",
        date: "2/2/2024",
        tentative_stage_date: "2/26/2024",
        rooms: [
          "Entry", "Living Room", "Kitchen", "Dining Room", "Power", 
          "Primary Bedroom & Bathroom", "Family Bathroom", 
          "Girls Bedroom", "Boys Bedroom", "Bonus Room", 
          "Bonus Bath", "Workspace"
        ],
        staging_fees: [
          { description: "Total Design Fee", amount: "$3,410.00" },
          { description: "Total Rental Fee", amount: "$2,914.00 plus tax" },
          { description: "Total", amount: "$6,324.00 (plus tax on rental portion)" },
          { description: "Add On Kids Playroom (3rd Floor)", amount: "$859.00 (plus tax on rental)" },
          { description: "Add On Outdoor Space", amount: "$825.00 (plus tax on rental)" },
          { description: "Add On Basement Office", amount: "$755.00 (plus tax on rental)" }
        ],
        terms: [
          "We offer a 45-day rental period for the first billing period with each additional billing cycle billed at 30 days.",
          "After the initial 45 days, any additional time is prorated.",
          "The design fee is a one-time fee. This covers the cost of the design, installation, and de-stage.",
          "The rental is a monthly recurring fee."
        ]
      }
  
      respond_to do |format|
        format.html # Render HTML if needed
        format.pdf do
          render pdf: "estimations_pdf", # The name of the PDF file
                 template: "project_estimations/estimations_pdf.html.erb", # Path to your view
                 locals: { project_data: @project_data },
                 layout: "pdf" # Optional: Specify a layout if needed
        end
      end
    end
    def project_proposal_pdf
        @project_data = {}
        respond_to do |format|
            format.html # Render HTML if needed
            format.pdf do
                render pdf: "estimations_pdf", # The name of the PDF file
                        template: "project_estimations/project_proposal.html.erb", # Path to your view
                        locals: { project_data: @project_data },
                        layout: "pdf" # Optional: Specify a layout if needed
            end            
        end
    end

    def create_estimation
        estimation_params = {
        email: params[:email],
        name: params[:name],
        message: params[:message],
        estimation_date: params[:estimation_date],
        tentative_stage_date: params[:tentative_stage_date],
        rooms_to_stage: params[:rooms_to_stage],
        total_design_fee: params[:total_design_fee],
        total_rental_fee: params[:total_rental_fee],
        total: params[:total],
        add_on_kids_playroom: params[:add_on_kids_playroom],
        add_on_outdoor_space: params[:add_on_outdoor_space],
        add_on_basement_office: params[:add_on_basement_office],
        contract_terms: params[:contract_terms],
        regards: params[:regards]
        }
        ProjectEstimationJob.perform_later(estimation_params)
        redirect_to account_orders_path, notice: "Estimation PDF generated."
    end  
    def load
      file_path = Rails.root.join('public', 'sample_product_file.csv')

      CSV.foreach(file_path, headers: true) do |row|
          # Convert CSV row to a hash with symbolized keys
          product_attributes = row.to_h.symbolize_keys
      
          # Create the product
          product = Product.create(
              product: product_attributes[:"Product Name"],
              width: product_attributes[:Width],
              height: product_attributes[:Height],
              depth: product_attributes[:Depth],
              customer_id: 20400,
              long_description: product_attributes[:long_description],
              site_id: 30,
              category_id: Category.first(name: "Wall Decor", site_id: 30)&.id,
              quantity: product_attributes[:Quantity],
              sku: product_attributes[:SKU],
              type: "Rental",
              manufacture_name: '-',
              manufacture_number: '-',
              initials: '-',
              portrait: product_attributes[:"P/L"]&.include?('P') ? 1 : 0,
              landscape: product_attributes[:"P/L"]&.include?('L') ? 1 : 0,
              sdn_cost: 1,
              rent_per_month: 1,
              sale_price: 1,
              available: Time.now,
              reserve_reason: '-',
              bin_id: SiteBin.first(site_id: 30, bin: product_attributes[:bin_id])&.id || 100000
          )
      
          # Check if the product has errors (validity check)
          unless product.errors.empty?
              # Output the error messages if there are any validation issues
              puts "Product failed to create due to validation errors:"
  
          else
              puts product.inspect + " Product created successfully."
      
              # Process color, material, and size options
              arr_colors = []
              arr_materials = []
              arr_sizes = []
      
              product_attributes[:Color]&.split(',').each do |c|
                  yuxi_option = Option.first(tag: 'COLOR', label: c.strip)&.id
                  arr_colors << yuxi_option
              end if product_attributes[:Color].present?
      
              product_attributes[:Material]&.split(',').each do |c|
                  yuxi_option = Option.first(tag: 'MATERIAL', label: c.strip)&.id
                  arr_materials << yuxi_option
              end if product_attributes[:Material].present?
      
              product_attributes[:Size]&.split('-').each do |c|
                  yuxi_option = Option.first(label: c.strip)&.id
                  arr_sizes << yuxi_option
              end if product_attributes[:Size].present?
      
              # Create ProductOption associated with the product
              yuxi_products = ProductOption.create(
                  product_id: product.id,
                  category_id: Category.first(name: "Art", site_id: 30)&.id,
                  material_id: arr_materials.join(','),
                  size_id: arr_sizes.join(','),
                  color_id: arr_colors.join(','),
                  is_premium: 0
              )
      
              puts yuxi_products.inspect + " YUXI products created."
      
              # Create ProductPiece for each quantity
              product_attributes[:Quantity].to_i.times do
                  pp = ProductPiece.last
                  pp_code = pp.epc_code.to_i + 1
                  pp_id = pp.product_epc_id.to_i + 1
      
                  pp = ProductPiece.create(
                      product_id: product.id,
                      order_line_id: 0,
                      epc_code: pp_code,
                      product_epc_id: pp_id
                  )
                  puts pp.inspect + " YUXI piece created."
              end
          end
      end
    end      

  end
  