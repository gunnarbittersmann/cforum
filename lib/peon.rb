# -*- coding: utf-8 -*-

dir = File.dirname(__FILE__)
require File.join(dir, "..", "config", "boot")
require File.join(dir, "..", "config", "environment")
require File.join(dir, 'tools.rb')

module Peon
  module Tasks

    class PeonTask
      include CForum::Tools
      include PublishHelper
      include AuditHelper

      def root_path
        Rails.application.config.action_controller.relative_url_root || '/'
      end

      def root_url
        'http://' + ActionMailer::Base.default_url_options[:host] + root_path
      end

      def initialize
        @config_manager = Peon::Grunt.instance.config_manager
        @notification_center = Peon::Grunt.instance.notification_center
      end

      def conf(name, forum = nil)
        @config_manager.get(name, nil, forum)
      end

      def uconf(name, user, forum)
        @config_manager.get(name, user, forum)
      end

      def notify_user(user, hook, subject, path, oid, otype, icon = nil)
        return if not hook.blank? and @config_manager.get(hook, user) != 'yes'

        n = CfNotification.create!(
          recipient_id: user.user_id,
          subject: subject,
          path: path,
          icon: icon,
          oid: oid,
          otype: otype,
          created_at: DateTime.now,
          updated_at: DateTime.now
        )

        publish('notification:create',
                {type: 'notification', notification: n},
                '/users/' + user.user_id.to_s)
      end

      def work_work(args)
      end
    end

  end

end

class Object
  def peon(args = {})
    args = {max_tries: 1, work_done: false,
            arguments: [], queue_name: 'peon'}.merge(args)

    args[:arguments] = args[:arguments].to_json

    j = CfPeonJob.create!(args)
    CfPeonJob.connection.execute 'NOTIFY ' + args[:queue_name] + ", '" + j.peon_job_id.to_s + "'"

    j
  end
end

# eof
