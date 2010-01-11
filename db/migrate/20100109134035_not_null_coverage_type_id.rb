class NotNullCoverageTypeId < ActiveRecord::Migration
  def self.up
    DB.execute("ALTER TABLE jobs ALTER coverage_type_id SET NOT NULL")
  end

  def self.down
  end
end
