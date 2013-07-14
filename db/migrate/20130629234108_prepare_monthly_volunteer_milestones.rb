class PrepareMonthlyVolunteerMilestones < ActiveRecord::Migration
  def self.up
    add_column :contacts, :next_monthly_milestone, :integer, :default => 100
    Contact.connection.execute("UPDATE contacts SET next_monthly_milestone=(SELECT (ceil((sum(duration)+1)/100)*100) FROM volunteer_tasks WHERE contact_id=contacts.id GROUP BY contact_id)")
    Contact.connection.execute("UPDATE contacts SET next_monthly_milestone=100 WHERE next_monthly_milestone IS NULL OR next_monthly_milestone < 100")
  end

  def self.down
  end
end
