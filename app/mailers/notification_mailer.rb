class NotificationMailer < ActionMailer::Base
  default from: 'from@email.com'

  def notification_email(project, email)
    @project = project
    mail(to: email, subject: "Project #{project} crashed")
  end
end
