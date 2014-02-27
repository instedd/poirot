class NotificationMailer < ActionMailer::Base
  default from: Settings.mailer.default_from

  def notification_email(notification, activities)
    @notification = notification
    @activities = activities
    mail(to: notification.email, subject: notification.subject)
  end
end
