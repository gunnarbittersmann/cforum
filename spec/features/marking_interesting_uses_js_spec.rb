# -*- coding: utf-8 -*-

require "rails_helper"

include Warden::Test::Helpers
Warden.test_mode!

describe "marking as interesting uses JS" do
  let(:message) { create(:cf_message) }
  let(:user) { create(:cf_user) }

  before(:each) { login_as(user , scope: :user) }

  include CForum::Tools

  it "doesn't reload when clicking the mark interesting icon", js: true do
    visit cf_forum_path(message.forum)

    page.find('#m' + message.message_id.to_s + ' .mark-interesting').click
    wait_for_ajax
    expect(page.body).to have_css('#m' + message.message_id.to_s + ' .mark-boring')
    expect(CfInterestingMessage.where(user_id: user.user_id,
                                      message_id: message.message_id).first).not_to be_nil

    page.find('#m' + message.message_id.to_s + ' .mark-boring').click
    wait_for_ajax
    expect(page.body).to have_css('#m' + message.message_id.to_s + ' .mark-interesting')
    expect(CfInterestingMessage.where(user_id: user.user_id,
                                      message_id: message.message_id).first).to be_nil
  end

end

# eof
