require_relative 'rails_config'

ActionMailer::Base.default_url_options[:host] = Settings.mailer.host
ActionMailer::Base.default :from => Settings.mailer.default_from

ActionMailer::Base.delivery_method = Settings.mailer.delivery_method.to_sym            if Settings.mailer.delivery_method
ActionMailer::Base.smtp_settings.merge!(Settings.mailer.smtp_settings.to_hash)         if Settings.mailer.delivery_method == 'smtp'     && Settings.mailer.smtp_settings
ActionMailer::Base.sendmail_settings.merge!(Settings.mailer.sendmail_settings.to_hash) if Settings.mailer.delivery_method == 'sendmail' && Settings.mailer.sendmail_settings

