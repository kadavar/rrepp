class NotificationMailer < ActionMailr::Base
  default_from 'example@example.com'

  def notification_email(project, email)
    mail(to: email, subject: "Project #{project} crashed")
  end
end
