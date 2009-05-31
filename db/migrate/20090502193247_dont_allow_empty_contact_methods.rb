class DontAllowEmptyContactMethods < ActiveRecord::Migration
  def self.up
    DB.execute("DELETE FROM contact_methods WHERE char_length(value) = 0 OR value IS NULL;")
    DB.execute("ALTER TABLE contact_methods ADD CONSTRAINT contact_methods_not_empty CHECK (char_length(value) > 0);")
    DB.execute("ALTER TABLE contact_methods ALTER COLUMN value SET NOT NULL;")
  end

  def self.down
    DB.execute("ALTER TABLE contact_methods DROP CONSTRAINT contact_methods_not_empty;")
    DB.execute("ALTER TABLE contact_methods ALTER COLUMN value DROP NOT NULL;")
  end
end
