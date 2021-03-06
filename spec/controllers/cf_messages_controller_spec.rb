# -*- coding: utf-8 -*-

require "rails_helper"

RSpec.describe CfMessagesController, type: :controller do
  let(:admin) { create(:cf_user_admin) }
  let(:message) { create(:cf_message) }
  let(:tag) { create(:cf_tag, forum: message.forum) }

  before(:each) do
    # ensure that message and tag exist
    message
    tag

    s = CfSetting.new
    s.options['min_tags_per_message'] = 1
    s.options['max_tags_per_message'] = 3
    s.save!
  end

  describe "GET #show" do
    render_views

    it "shows a message" do
      get :show, message_params_from_slug(message)
    end

    it "shows no versions link if there are no versions but an edit_author is set" do
      message.edit_author = admin.username
      message.save!

      get :show, message_params_from_slug(message)

      expect(response.body).not_to have_css('.versions')
    end

    it "shows versions link if there are versions" do
      message.edit_author = admin.username
      message.versions.create!(subject: message.subject, content: message.content, author: message.author)
      message.save!

      get :show, message_params_from_slug(message)

      expect(response.body).to have_css('.versions')
    end
  end

  describe "GET #new" do
    it "shows a new message form" do
      get :new, message_params_from_slug(message)

      expect(assigns(:message)).to be_a_new(CfMessage)
    end
  end

  describe "POST #create" do
    it "creates a new message" do
      expect {
        post :create, message_params_from_slug(message).merge({tags: [tag.tag_name],
                                                               cf_message: attributes_for(:cf_message, forum: message.thread.forum) })
      }.to change(CfMessage, :count).by(1)
      expect(response).to redirect_to cf_message_url(message.thread, assigns(:message))
    end

    it "fails to create a new message because of invalid tags" do
      post :create, message_params_from_slug(message).merge({cf_message: attributes_for(:cf_message, forum: message.thread.forum) })

      expect(response).to render_template "new"
    end

    it "fails to create a new message because of missing attributes" do
      attrs = attributes_for(:cf_message, forum: message.thread.forum)
      attrs.delete(:author)

      post :create, message_params_from_slug(message).merge({tags: [tag.tag_name], cf_message: attrs})

      expect(response).to render_template "new"
    end
  end

  describe "POST retag" do
    it "changes tags" do
      sign_in admin

      expect {
        post :retag, message_params_from_slug(message).merge({ tags: [tag.tag_name] })
      }.to change(message.tags, :count).by(1)
    end

    it "creates new tag" do
      sign_in admin

      expect {
        post :retag, message_params_from_slug(message).merge({tags: ["old republic"] })
      }.to change(message.tags, :count).by(1)
    end
  end
end

# eof
