class DifferentiateRequiredFeeTypes < ActiveRecord::Migration
  def self.up
    gt = GizmoType.find_by_name('service_fee')
    gt_p = gt.clone
    gt_e = gt.clone
    gt_t = gt.clone
    {"other" => gt, "pickup" => gt_p, "education" => gt_e, "tech support" => gt_t}.each do |name, o|
      o.description = "Required Service Fee - #{name.titleize}"
      o.name = 'service_fee_' + name.sub(' ', '_')
      o.gizmo_contexts = [GizmoContext.donation]
      o.save!
    end
  end

  def self.down
  end
end
