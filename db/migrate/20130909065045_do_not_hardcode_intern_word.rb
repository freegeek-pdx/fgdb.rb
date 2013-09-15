class DoNotHardcodeInternWord < ActiveRecord::Migration
  def self.up
    DB.exec("UPDATE contacts SET volunteer_intern_title = volunteer_intern_title || ' Intern' WHERE volunteer_intern_title IS NOT NULL AND volunteer_intern_title <> '';")
  end

  def self.down
  end
end
