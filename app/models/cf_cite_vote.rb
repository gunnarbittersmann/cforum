# -*- encoding: utf-8 -*-

class CfCiteVote < ActiveRecord::Base
  UPVOTE   = 1
  DOWNVOTE = 0

  self.primary_key = 'cite_vote_id'
  self.table_name  = 'cites_votes'

  belongs_to :user, class_name: 'CfUser'
  belongs_to :cite, class_name: 'CfCite'

  validates_presence_of :user_id
  validates_uniqueness_of :cite_id, presence: true, scope: :user_id
  validates :vote_type, inclusion: [UPVOTE, DOWNVOTE], presence: true
end

# eof
