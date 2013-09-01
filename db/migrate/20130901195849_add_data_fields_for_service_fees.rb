class AddDataFieldsForServiceFees < ActiveRecord::Migration
  def self.up
    add_column :donations, :reported_resolved_invoices_cents, :integer, :default => 0, :null => false
    add_column :donations, :reported_recycling_fees_cents, :integer, :default => 0, :null => false
    add_column :donations, :reported_pickup_fees_cents, :integer, :default => 0, :null => false
    add_column :donations, :reported_education_fees_cents, :integer, :default => 0, :null => false
    add_column :donations, :reported_tech_support_fees_cents, :integer, :default => 0, :null => false
    add_column :donations, :reported_other_fees_cents, :integer, :default => 0, :null => false

    DB.exec("UPDATE donations SET
      reported_resolved_invoices_cents = (SELECT COALESCE(SUM(unit_price_cents * gizmo_count), 0)
                                          FROM gizmo_events JOIN gizmo_types ON gizmo_types.id = gizmo_type_id
                                          WHERE gizmo_types.name = 'invoice_resolved' AND donation_id = donations.id),
      reported_pickup_fees_cents = (SELECT COALESCE(SUM(unit_price_cents * gizmo_count), 0)
                                          FROM gizmo_events JOIN gizmo_types ON gizmo_types.id = gizmo_type_id
                                          WHERE gizmo_types.name = 'service_fee_pickup' AND donation_id = donations.id),
      reported_education_fees_cents = (SELECT COALESCE(SUM(unit_price_cents * gizmo_count), 0)
                                          FROM gizmo_events JOIN gizmo_types ON gizmo_types.id = gizmo_type_id
                                          WHERE gizmo_types.name = 'service_fee_education' AND donation_id = donations.id),
      reported_tech_support_fees_cents = (SELECT COALESCE(SUM(unit_price_cents * gizmo_count), 0)
                                          FROM gizmo_events JOIN gizmo_types ON gizmo_types.id = gizmo_type_id
                                          WHERE gizmo_types.name = 'service_fee_tech_support' AND donation_id = donations.id),
      reported_other_fees_cents = (SELECT COALESCE(SUM(unit_price_cents * gizmo_count), 0)
                                          FROM gizmo_events JOIN gizmo_types ON gizmo_types.id = gizmo_type_id
                                          WHERE gizmo_types.name = 'service_fee_other' AND donation_id = donations.id);")
    DB.exec("UPDATE donations SET reported_recycling_fees_cents = reported_required_fee_cents - reported_resolved_invoices_cents - reported_pickup_fees_cents - reported_education_fees_cents - reported_tech_support_fees_cents - reported_other_fees_cents;")
  end

  def self.down
    remove_column :donations, :reported_resolved_invoices_cents
    remove_column :donations, :reported_recycling_fees_cents
    remove_column :donations, :reported_pickup_fees_cents
    remove_column :donations, :reported_education_fees_cents
    remove_column :donations, :reported_tech_support_fees_cents
    remove_column :donations, :reported_other_fees_cents
  end
end
