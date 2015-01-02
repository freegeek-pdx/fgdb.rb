class NewFee < ActiveRecord::Migration
  def self.up
    gt = GizmoType.find_by_name('monitor_crt')
    gt.required_fee_cents = 1000
    gt.save
  end

  def self.down
  end
end
