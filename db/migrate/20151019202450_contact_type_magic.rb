class ContactTypeMagic < ActiveRecord::Migration
  def self.up
    DB.exec("ALTER TABLE contact_types_contacts ADD COLUMN created_at timestamp without time zone;")
    DB.exec("ALTER TABLE contact_types_contacts ADD COLUMN id BIGSERIAL PRIMARY KEY;")
  end

  def self.down
  end
end
