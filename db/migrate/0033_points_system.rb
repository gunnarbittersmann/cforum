# -*- coding: utf-8 -*-

class PointsSystem < ActiveRecord::Migration
  def up
    execute %q{
CREATE TABLE scores (
  score_id BIGSERIAL NOT NULL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
  vote_id BIGINT NOT NULL REFERENCES votes(vote_id) ON DELETE CASCADE ON UPDATE CASCADE,
  value INTEGER NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX scores_user_id_vote_id_idx ON scores (user_id, vote_id);
    }
  end

  def down
    execute "DROP TABLE scores;"
  end
end

# eof