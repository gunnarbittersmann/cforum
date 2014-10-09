# -*- coding: utf-8 -*-

class MarkUnreadController < ApplicationController
  def mark_unread
    raise CForum::ForbiddenException.new if current_user.blank?

    @thread, @message, @id = get_thread_w_post

    CfMessage.connection.
      execute("DELETE FROM read_messages WHERE user_id = " +
              current_user.user_id.to_s + " AND message_id = " +
              @message.message_id.to_s)
    redirect_to cf_forum_url(@thread.forum.slug), notice: t('plugins.mark_read.marked_unread')
  end
end


# eof