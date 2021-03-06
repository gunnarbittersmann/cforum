# -*- coding: utf-8 -*-

class CitesController < ApplicationController
  authorize_action([:edit, :update, :destroy]) { may?(RightsHelper::MODERATOR_TOOLS) or authorize_admin }
  authorize_action(:vote_index) { authorize_user }

  before_action :set_cite, only: [:show, :edit, :update, :destroy, :vote]

  EDITED_CITE = 'edited_cite'

  def index(archived = true)
    @limit = conf('pagination').to_i
    @cites = CfCite.
             preload(:user, :creator_user, message: :forum).
             where(archived: archived).
             order('cite_id DESC').
             page(params[:page]).
             per(@limit)
  end

  def vote_index
    index(false)
    @cites = @cites.preload(:votes)
  end

  def vote
    if current_user.blank? or @cite.archived?
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.insufficient_rights_to_upvote')
          redirect_to cites_url
        end

        format.json { render json: { status: 'error', message: t('messages.do_not_vote_yourself') } }
      end
    end

    vtype = params[:type] == 'up' ? CfCiteVote::UPVOTE : CfCiteVote::DOWNVOTE

    @vote = CfCiteVote.where(user_id: current_user.user_id,
                             cite_id: @cite.cite_id).first

    if @vote.blank?
      @vote = CfCiteVote.new(cite_id: @cite.cite_id,
                             user_id: current_user.user_id,
                             vote_type: vtype)

      if @vote.save
        respond_to do |format|
          format.html { redirect_to cites_vote_url, notice: t('messages.successfully_voted') }
          format.json do
            @cite.votes.reload
            render json: { status: 'success', score: @cite.score_str, message: t('messages.successfully_voted') }
          end
        end

      else
        respond_to do |format|
          format.html { redirect_to cites_vote_url, notice: t('messages.something_went_wrong') }
          format.json do
            @cite.votes.reload
            render json: { status: 'success', score: @cite.score_str, message: t('messages.something_went_wrong') }
          end
        end
      end

      return
    end

    if @vote.vote_type == vtype
      @vote.destroy

      respond_to do |format|
        format.html { redirect_to cites_vote_url, notice: t('messages.vote_removed') }
        format.json do
          @cite.votes.reload
          render json: { status: 'success', score: @cite.score_str, message: t('messages.vote_removed') }
        end
      end

      return
    end

    @vote.vote_type = vtype
    if @vote.save
      respond_to do |format|
        format.html { redirect_to cites_vote_url, notice: t('messages.successfully_voted') }
        format.json do
          @cite.votes.reload
          render json: { status: 'success', score: @cite.score_str, message: t('messages.successfully_voted') }
        end
      end

      return
    end

    respond_to do |format|
      format.html { redirect_to cites_vote_url, notice: t('messages.something_went_wrong') }
      format.json do
        @cite.votes.reload
        render json: { status: 'success', score: @cite.score_str, message: t('messages.something_went_wrong') }
      end
    end
  end

  def show
    if not current_user.blank? and uconf('delete_read_notifications_on_cite') == 'yes'
      CfNotification.
        where(recipient_id: current_user.user_id,
              oid: @cite.cite_id,
              otype: 'cite:create').
        delete_all
    end

    if @cite.archived?
      @next_cite = CfCite.
                   where('cite_id < ?', @cite.cite_id).
                   order('cite_id DESC').
                   where(archived: true).
                   first
      @prev_cite = CfCite.
                   where('cite_id > ?', @cite.cite_id).
                   where(archived: true).
                   order('cite_id ASC').
                   first
    end
  end

  # GET /cites/new
  def new
    @cite = CfCite.new
  end

  # GET /cites/1/edit
  def edit
  end

  # POST /cites
  def create
    @cite = CfCite.new(cite_params)
    @cite.creator_user_id = current_user.user_id unless current_user.blank?

    if not @cite.url.blank? and @cite.url[0..(root_url.length-1)] == root_url and @cite.url =~ /\/\w+(\/\d{4,}\/[a-z]{3}\/\d{1,2}\/[^\/]+)\/(\d+)/
      slug = $1
      mid = $2

      @thread = CfThread.preload(:forum).where(slug: slug).first

      unless @thread.blank?
        @message = CfMessage.where(thread_id: @thread.thread_id,
                                   message_id: mid).first
      end

      unless @message.blank?
        @cite.message_id = @message.message_id
        @cite.user_id = @message.user_id
        @cite.cite_date = @message.created_at
      end
    else
      @cite.cite_date = DateTime.now
    end

    @cite.author = @message.author if @cite.author.blank? and not @message.blank?
    @cite.creator = current_user.username if @cite.creator.blank? and not current_user.blank?

    if @cite.save
      if current_user
        @vote = CfCiteVote.create(cite_id: @cite.cite_id,
                                  user_id: current_user.user_id,
                                  vote_type: CfCiteVote::UPVOTE)
      end

      peon(class_name: 'CitesNotifier',
           arguments: {type: 'create', cite_id: @cite.cite_id})

      audit(@cite, 'create')
      redirect_to cite_url(@cite), notice: t('cites.created')
    else
      render :new
    end
  end

  # PATCH/PUT /cites/1
  def update
    if @cite.update(cite_params)
      audit(@cite, 'update')
      notification_center.notify(EDITED_CITE, @cite)
      redirect_to cite_url(@cite), notice: t('cites.updated')
    else
      render :edit
    end
  end

  # DELETE /cites/1
  def destroy
    @cite.destroy

    audit(@cite, 'destroy')
    peon(class_name: 'CitesNotifier',
         arguments: {type: 'destroy', cite_id: @cite.cite_id})

    redirect_to cites_url, notice: t('cites.destroyed')
  end

  def redirect
    id = params[:id].gsub(/\D+/, '')
    @cite = CfCite.where(old_id: id).first!
    redirect_to cite_url(@cite), status: 301
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_cite
    @cite = CfCite.preload(:user, :creator_user, message: :forum).find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def cite_params
    allowed_attribs = [:cite, :url, :author, :creator]

    params.require(:cf_cite).permit(*allowed_attribs)
  end
end

# eof
