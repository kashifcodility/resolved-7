require 'fileutils'

class GenerateProjectPdfJob < ApplicationJob
  queue_as :default

  def perform(project_id)
    project = ProjectWalkThrough.find(project_id)
    @step1 = eval(project.step1)
    @step2 = eval(project.step2)
    @step3 = eval(project.step3)
    @step4 = eval(project.step4)
    @step5 = eval(project.step5)
    @step6 = eval(project.step6)
    @step7 = eval(project.step7)
    @step8 = eval(project.step8)
    @step9 = eval(project.step9)
    @step10 = eval(project.step10)
    @step11 = eval(project.step11)
    @step12 = eval(project.step12)
    @step13 = eval(project.step13)
    @step14 = eval(project.step14)
    @step15 = eval(project.step15)
    @step16 = eval(project.step16)
    @step17 = eval(project.step17)


    pdf = WickedPdf.new.pdf_from_string(
      ApplicationController.render(
        template: 'project_walk_through/generate_pdf.html.erb',
        layout: 'pdf.html',
        assigns: { step1: @step1, step2: @step2, step3: @step3,
                   step4: @step4, step5: @step5, step6: @step6,
                   step7: @step7, step8: @step8, step9: @step9,
                   step10: @step10, step11: @step11, step12: @step12,
                   step13: @step13, step14: @step14, step15: @step15,
                   step16: @step16, step17: @step17 }
      )
    )

    # For example, to save it:
    # File.open(Rails.root.join('public', 'pdfs', "project_#{project_id}.pdf"), 'wb') do |file|
    #   file << pdf
    # end


    pdf_directory = Rails.root.join('public', 'pdfs')
    FileUtils.mkdir_p(pdf_directory) unless File.directory?(pdf_directory)

    pdf_path = pdf_directory.join("project-#{project.order.user.username}-#{project.order.id}.pdf")
    File.open(pdf_path, 'wb') { |file| file << pdf }

    # Send the email with the attachment
    ProjectMailer.project_pdf(project, pdf_path).deliver_now




  end
end
