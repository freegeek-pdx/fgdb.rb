class CleanUpCovered < ActiveRecord::Migration
  def self.up
    DB.exec("UPDATE systems
             SET covered = 'f'
             WHERE contract_id = 2;")
    DB.exec("UPDATE gizmo_events
             SET covered = 'f'
             FROM systems
             WHERE systems.id = gizmo_events.system_id
             AND system_id IS NOT NULL
             AND systems.contract_id = 2
             AND gizmo_events.covered = 't';")
    DB.exec("UPDATE gizmo_events
             SET covered = 'f'
             FROM donations
             WHERE donation_id IS NOT NULL
             AND donations.id = gizmo_events.donation_id
             AND donations.contract_id != 1;")
  end

  def self.down
  end
end
