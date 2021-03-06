#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

dir = File.dirname(__FILE__)
require File.join(dir, "..", "config", "boot")
require File.join(dir, "..", "config", "environment")
require File.join(dir, '..', 'lib', 'tools.rb')

include CForum::Tools
include ActionView::Helpers::TextHelper

Rails.logger = Logger.new(Rails.root + 'log/reindex.log')
ActiveRecord::Base.logger = Rails.logger

public

def root_path
  Rails.application.config.action_controller.relative_url_root || '/'
end

def root_url
  (ActionMailer::Base.default_url_options[:protocol] || 'http') + "://" + ActionMailer::Base.default_url_options[:host] + root_path
end

def conf(name)
  $config_manager.get(name, nil, nil)
end

$config_manager = ConfigManager.new
section = SearchSection.find_by_name(I18n.t('cites.cites'))
no_messages = 1000
current_block = 0
start_date = nil
start_date = Time.zone.parse(ARGV[0]) if ARGV.length > 0

section = SearchSection.create!(name: I18n.t('cites.cites'), position: -1) if section.blank?
base_relevance = conf('search_cites_relevance')

begin
  cites = CfCite.
         includes(:user, :creator_user).
         order(:cite_id).
         limit(no_messages).
         offset(no_messages * current_block).
         where(archived: true)

  if start_date
    cites = cites.where('created_at >= ?', start_date)
  end


  current_block += 1
  i = 0

  CfMessage.transaction do
    cites.each do |cite|
      doc = SearchDocument.where(url: root_url + 'cites/' + cite.cite_id.to_s).first
      if doc.blank?
        doc = SearchDocument.new(url: root_url + 'cites/' + cite.cite_id.to_s)
      end

      doc.author = cite.author
      doc.user_id = cite.user_id
      doc.title = ''
      doc.content = cite.cite
      doc.search_section_id = section.search_section_id
      doc.relevance = base_relevance.to_f
      doc.lang = Cforum::Application.config.search_dict
      doc.document_created = cite.created_at
      doc.tags = []

      doc.save!

      i += 1
      puts cite.created_at.strftime('%Y-%m-%d') + ' - ' + cite.message_id.to_s if i == no_messages - 1
    end
  end
end while not cites.blank?


# eof
