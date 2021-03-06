# -*- coding: utf-8 -*-

class NotifyFlaggedMailer < ActionMailer::Base
  def new_flagged(user, message)
    @user    = user
    @message = message

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: I18n.t(
        'plugins.flag_plugin.message_has_been_flagged',
        subject: @message.subject,
        author: @message.author),
    )
  end

end

# eof
