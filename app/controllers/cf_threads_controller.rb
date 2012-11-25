# -*- encoding: utf-8 -*-

class CfThreadsController < ApplicationController
  load_resource
  before_filter :authorize!

  SHOW_THREADLIST  = "show_threadlist"
  SHOW_THREAD      = "show_thread"
  SHOW_NEW_THREAD  = "show_new_thread"
  NEW_THREAD       = "new_thread"
  NEW_THREAD_SAVED = "new_thread_saved"

  def index
    forum  = current_forum
    @page  = params[:p].to_i
    @limit = uconf('pagination', 50)
    @page  = 0 if @page < 0

    conditions = {}
    conditions[:forum_id] = forum.forum_id if forum
    conditions[:archived] = false if conf('use_archive')
    conditions[:messages] = {deleted: false} unless params.has_key?(:view_all)

    # the „no forum” case is much more complex; we have to do it partly manually
    # to avoid DISTINCT
    sql = "SELECT thread_id FROM cforum.threads WHERE "
    crits = []

    if forum
      crits << "forum_id = " + forum.forum_id.to_s

      unless params[:view_all]
        crits << "EXISTS(SELECT message_id FROM cforum.messages WHERE thread_id = threads.thread_id AND deleted = false)"
      end
    else
      crits << "forum_id IN (SELECT forum_id FROM cforum.forum_permissions WHERE user_id = " + current_user.user_id.to_s + ")" if current_user
      crits << "forum_id IN (SELECT forum_id FROM cforum.forums WHERE public = true)"

      crits = ["(" + crits.join(" OR ") + ")"]

      unless params[:view_all]
        crits << "EXISTS(SELECT message_id FROM cforum.messages WHERE thread_id = threads.thread_id AND deleted = false)"
      end
    end
    sql << crits.join(" AND ")
    sql << " ORDER BY threads.created_at DESC LIMIT #{@limit} OFFSET #{@limit * @page}"

    result = CfThread.connection.execute(sql)

    ids = []
    result.each do |row|
      ids << row['thread_id'].to_i
    end

    @threads = CfThread.
      preload(:forum, :tags).
      includes(:messages => :owner).
      where(conditions).
      where(thread_id: ids).
      order('cforum.threads.created_at DESC').
      limit(@limit).
      offset(@limit * @page)

    if forum
      rslt = CfForum.connection.execute("SELECT cforum.counter_table_get_count('threads', " +
        current_forum.forum_id.to_s +
        ") AS cnt")
    else
      rslt = CfForum.connection.execute("SELECT SUM(difference) AS cnt FROM cforum.counter_table WHERE table_name = 'threads'")
    end

    @all_threads_count = rslt[0]['cnt'].to_i

    @threads.each do |t|
      t.gen_tree
      t.sort_tree
    end

    notification_center.notify(SHOW_THREADLIST, @threads)
  end

  def show
    @id = CfThread.make_id(params)

    conditions = {slug: @id}
    conditions[:messages] = {deleted: false} unless params[:view_all]

    @thread = CfThread.includes(:messages => :owner).where(conditions).first
    raise CForum::NotFoundException.new if @thread.blank?

    @thread.gen_tree
    @thread.sort_tree

    notification_center.notify(SHOW_THREAD, @thread)
  end

  def edit
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by_slug!(@id)

    @thread.gen_tree
    @thread.sort_tree
  end

  def new
    @thread = CfThread.new
    @thread.message = CfMessage.new

    notification_center.notify(SHOW_NEW_THREAD, @thread)
  end

  def create
    now = Time.now

    @forum = current_forum

    @thread  = CfThread.new()
    @message = CfMessage.new(params[:cf_thread][:message])
    @thread.messages << @message
    @thread.message  =  @message

    @thread.forum_id  = @forum.forum_id
    @message.forum_id = @forum.forum_id
    @message.user_id  = current_user.user_id unless current_user.blank?
    @message.content  = content_to_internal(@message.content, uconf('quote_char', '> '))

    notification_center.notify(NEW_THREAD, @thread, @message)

    @preview = true if params[:preview]

    respond_to do |format|
      if not @preview and @thread.save
        notification_center.notify(NEW_THREAD_SAVED, @thread, @message)

        format.html { redirect_to cf_message_url(@thread, @message), notice: I18n.t("threads.created") }
        format.json { render json: @thread, status: :created, location: @thread }
      else
        format.html { render action: "new" }
        format.json { render json: @thread.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  def moving
    @id     = CfThread.make_id(params)
    @thread = CfThread.includes(:forum).find_by_slug!(@id)

    @thread.gen_tree
    @thread.sort_tree

    if current_user.admin
      @forums = CfForum.order('name ASC').find :all
    else
      @forums = CfForum.where("public = true OR forum_id IN (SELECT forum_id FROM cforum.forum_permissions WHERE user_id = ?)", current_user.user_id).order('name ASC')
    end
  end

  def move
    moving

    @move_to = CfForum.find params[:move_to]
    raise CForum::ForbiddenException unless @forums.include?(@move_to)

    saved = false

    CfThread.transaction do
      @thread.forum_id = @move_to.forum_id
      @thread.save

      @thread.messages.each do |m|
        m.forum_id = @move_to.forum_id
        m.save
      end

      saved = true
    end

    respond_to do |format|
      if saved
        format.html { redirect_to cf_message_url(@thread, @thread.message) }
      else
        format.html { render :moving }
      end
    end
  end

  include AuthorizeForum
end

# eof
