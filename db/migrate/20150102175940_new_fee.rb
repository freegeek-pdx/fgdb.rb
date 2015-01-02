class NewFee < ActiveRecord::Migration
  def self.up
    for k, v in {'monitor_crt' => 1000}
      gt = GizmoType.find_by_name(k)
      gt.required_fee_cents = v
      gt.save!
    end

    for k, v in {'tv_lcd' => 600, 'monitor_lcd' => 500, 'system_lcd' => 800, 'system' => 800, 'keyboard' => 300, 'mouse' => 300, 'misc_item' => 500, 'bag_box_misc' => 500, 'ups' => 600, 'smart_phone' => 300, 'server' => 600, 'net_device' => 200}
      gt = GizmoType.find_by_name(k)
      gt.suggested_fee_cents = v
      gt.save!
    end

    for k, v in {'printer' => 14, 'keyboard' => 15, 'mouse' => 16, 'misc_item' => 100, 'bag_box_misc' => 101, 'av_gizmo' => 98}
      gt = GizmoType.find_by_name(k)
      gt.rank = v
      gt.save!
    end    
  end

  def self.down
  end
end
