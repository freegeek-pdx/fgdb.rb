#!/usr/bin/ruby

ENV['RAILS_ENV']="production"

require File.dirname(__FILE__) + '/config/boot'
require File.expand_path(File.dirname(__FILE__) + "/config/environment")

f = File.open("output/donations", "w")
Donation.find(:all, :order => 'created_at ASC').each{|d|
  string = ""
  string += d.id.to_s + " "
  string += d.reported_total_cents.to_s + " "
  string += d.calculated_required_fee_cents.to_s + " "
  string += d.calculated_suggested_fee_cents.to_s + " "
  string += d.calculated_total_cents.to_s + " "
  string += d.cash_donation_owed_cents.to_s + " "
  string += d.cash_donation_paid_cents.to_s + " "
  string += d.required_fee_owed_cents.to_s + " "
  string += d.required_fee_paid_cents.to_s + " "
  string += d.required_paid?.to_s + " "
  string += d.invoiced?.to_s + " "
  string += d.overunder_cents(true).to_s + " "
  string += d.overunder_cents(false).to_s + " "
  f.write(string + "\n")
}
f.close

f = File.open("output/sales", "w")
Sale.find(:all, :order => 'created_at ASC').each{|s|
  string = ""
  string += s.id.to_s + " "
  string += s.calculated_total_cents.to_s + " "
  string += s.calculated_subtotal_cents.to_s + " "
  string += s.calculated_discount_cents.to_s + " "
  f.write(string + "\n")
}
f.close

f = File.open("output/gizmo_events", "w")
GizmoEvent.find(:all, :order => 'created_at ASC').each{|g|
  string = ""
  string += g.id.to_s + " "
  string += g.donation_id.to_s + " "
  string += g.sale_id.to_s + " "
  string += g.disbursement_id.to_s + " "
  string += g.recycling_id.to_s + " "
  string += g.unit_price_cents.to_s + " "
  string += g.as_is.to_s + " "
  string += g.description.to_s + " "
  string += g.size.to_s + " "
  f.write(string + "\n")
}
f.close
