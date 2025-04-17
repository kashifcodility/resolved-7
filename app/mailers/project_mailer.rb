class ProjectMailer < ApplicationMailer
  def project_pdf(project, pdf_path)
    @project = project
    attachments["project-#{project.order.user.username}-#{project.order.id}.pdf"] = File.read(pdf_path)
    mail(to: @project.order.user.email, subject: 'Your project walkthrough PDF.')
  end
  def estimation_pdf(email, pdf_path)
    @email = email
    attachments["estimation-#{email}.pdf"] = File.read(pdf_path)
    mail(to: email, subject: 'Your project estimation PDF.')
  end
end