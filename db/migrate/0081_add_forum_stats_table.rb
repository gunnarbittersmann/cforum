# -*- coding: utf-8 -*-

class AddForumStatsTable < ActiveRecord::Migration
  def up
    execute <<-SQL
CREATE TABLE forum_stats (
  forum_stat_id SERIAL PRIMARY KEY,
  forum_id INTEGER NOT NULL REFERENCES forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
  moment DATE NOT NULL,
  messages INTEGER NOT NULL,
  threads INTEGER NOT NULL,
  UNIQUE(forum_id, moment)
);

CREATE OR REPLACE FUNCTION gen_forum_stats(p_forum_id INTEGER) RETURNS INTEGER LANGUAGE plpgsql AS $body$
DECLARE
  v_min TIMESTAMP WITHOUT TIME ZONE;
  v_max TIMESTAMP WITHOUT TIME ZONE;
  v_now TIMESTAMP WITHOUT TIME ZONE;
BEGIN
  DELETE FROM forum_stats WHERE forum_id = p_forum_id;

  v_min := (SELECT MIN(DATE_TRUNC('day', created_at)) FROM messages);
  v_max := (SELECT NOW());

  v_now := v_min;
  while v_now < v_max LOOP
    INSERT INTO forum_stats (forum_id, moment, messages, threads)
      VALUES (p_forum_id, v_now,
              (SELECT COUNT(*) FROM messages WHERE forum_id = p_forum_id AND deleted = false AND created_at BETWEEN v_now AND ((v_now + interval '1 day') - interval '1 second')),
              (SELECT COUNT(*) FROM threads WHERE forum_id = p_forum_id AND deleted = false AND created_at BETWEEN v_now AND ((v_now + interval '1 day') - interval '1 second')));
    v_now := v_now + INTERVAL '1 day';
  END LOOP;

  RETURN 0;
END;
$body$;

SELECT gen_forum_stats(forum_id::integer) FROM forums;
    SQL
  end

  def down
    execute <<-SQL
DROP FUNCTION gen_forum_stats(p_forum_id INTEGER);
DROP TABLE forum_stats;
    SQL
  end
end

# eof
