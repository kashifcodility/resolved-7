require 'fileutils'
class ProjectEstimationJob < ApplicationJob
    queue_as :default
  
    def perform(estimation)
      pdf = WickedPdf.new.pdf_from_string(
            ApplicationController.render(
                template: 'project_estimations/estimations_pdf.html.erb',
                layout: 'pdf.html',
                assigns: {  email: estimation[:email],
                            name: estimation[:name],
                            regards: estimation[:regards],
                            tentative_stage_date: estimation[:tentative_stage_date],
                            message: estimation[:message],
                            estimation_date: estimation[:estimation_date],
                            rooms_to_stage: estimation[:rooms_to_stage],
                            total_design_fee: estimation[:total_design_fee],
                            total_rental_fee: estimation[:total_rental_fee],
                            total: estimation[:total],
                            add_on_kids_playroom: estimation[:add_on_kids_playroom],
                            add_on_outdoor_space: estimation[:add_on_outdoor_space],
                            add_on_basement_office: estimation[:add_on_basement_office],
                            contract_terms: estimation[:contract_terms]
                        }
            )
        )

        pdf_directory = Rails.root.join('public', 'pdfs')
        FileUtils.mkdir_p(pdf_directory) unless File.directory?(pdf_directory)

        pdf_path = pdf_directory.join("estimation-#{estimation[:email]}.pdf")
        File.open(pdf_path, 'wb') { |file| file << pdf }

        # Send the email with the attachment
        ProjectMailer.estimation_pdf(estimation[:email], pdf_path).deliver_now      
    end
end
  