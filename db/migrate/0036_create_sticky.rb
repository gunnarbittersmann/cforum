# -*- coding: utf-8 -*-

class CreateSticky < ActiveRecord::Migration
  def up
    execute <<-SQL
ALTER TABLE threads ADD COLUMN sticky BOOLEAN NOT NULL DEFAULT false;
    SQL
  end

  def down
    execute <<-SQL
ALTER TABLE threads DROP COLUMN sticky;
    SQL
  end
end

# eof
