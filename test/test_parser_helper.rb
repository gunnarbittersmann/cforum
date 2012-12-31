# -*- coding: utf-8 -*-

class MockObject
  include CForum::Tools
  include ParserHelper

  def initialize
    @config_manager = ConfigManager.new
  end

  def root_path
    Rails.application.config.action_controller.relative_url_root || '/'
  end

  def uconf(name, default = nil)
    @config_manager.get(name, default, current_user, current_forum)
  end

  def conf(name, default = nil)
    @config_manager.get(name, default, nil, current_forum)
  end

  def current_user
    nil
  end

  def current_forum
    nil
  end
end

# eof
