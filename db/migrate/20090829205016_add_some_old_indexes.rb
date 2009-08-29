class AddSomeOldIndexes < ActiveRecord::Migration
  def self.up
    DB.execute('CREATE index donations_contract_id ON donations (contract_id);')
    DB.execute('CREATE index systems_contract_id ON systems (contract_id);')
    DB.execute('CREATE index gizmo_events_system_id ON gizmo_events (system_id);')
    DB.execute('CREATE index gizmo_events_recycling_contract_id ON gizmo_events(recycling_contract_id);')
  end

  def self.down
  end
end
