# -*- coding: utf-8 -*-

class HideReadThreadsPlugin < Plugin
  def modify_threadlist_query_obj()
    if params[:srt] == 'yes'
      session[:srt] = true
    elsif params[:srt] == 'no'
      session.delete :srt
    end

    return if current_user.blank? or get('view_all') or uconf('hide_read_threads') != 'yes' or session[:srt]

    return Proc.new { |threads|
      threads.where("EXISTS(SELECT a.message_id FROM messages a LEFT JOIN read_messages b ON a.message_id = b.message_id AND b.user_id = ? WHERE thread_id = threads.thread_id AND read_message_id IS NULL AND a.deleted = false) OR EXISTS(SELECT a.message_id FROM messages AS a INNER JOIN interesting_messages USING(message_id) WHERE thread_id = threads.thread_id AND interesting_messages.user_id = ? AND deleted = false)",
                    current_user.user_id, current_user.user_id)
    }
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  hide_read_threads = HideReadThreadsPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfThreadsController::MODIFY_THREADLIST_QUERY_OBJ,
                  hide_read_threads)
end


# eof
