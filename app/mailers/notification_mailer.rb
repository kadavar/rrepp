class NotificationMailer < ActionMailer::Base
  default from: ENV['default_from']

  def notification_email(project, email)
    @project = project
    mail(to: email, subject: "Project #{project} crashed",template_name:'notification_email')
  end
end
