#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")
require File.join(File.dirname(__FILE__), "..", "lib", "peon")
require File.join(File.dirname(__FILE__), "..", "lib", "peon", "grunt")

# TODO add support for pathes below root
def cf_badge_path(b)
  return '/badges/' + b.slug
end

p = Peon::Tasks::PeonTask.new

CfBadgeUser.transaction do
  CfBadgeUser.delete_all
  badges = CfBadge.all

  CfUser.all.each do |u|
    badges.each do |b|
      if u.score >= b.score_needed
        u.badges_users.create(badge_id: b.badge_id)
        p.notify_user(
          u, '', I18n.t('badges.badge_won',
                        name: b.name,
                        mtype: I18n.t("badges.badge_medal_types." + b.badge_medal_type)),
          cf_badge_path(b), b.badge_id, 'badge'
        )
      end
    end
  end
end

# eof
