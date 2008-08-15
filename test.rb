#!/usr/bin/ruby

ENV['RAILS_ENV']="production"

require File.dirname(__FILE__) + '/config/boot'
require File.expand_path(File.dirname(__FILE__) + "/config/environment")

f = File.open("output/donations", "w")
Donation.connection.execute("SELECT id FROM donations ORDER BY id ASC LIMIT 20").to_a.map{|x| x['id'].to_i}.each{|x|
  d = Donation.find_by_id(x)
  string = ""
  string += d.id.to_s + " "
  string += d.reported_total_cents.to_s + " "
  string += d.calculated_required_fee_cents.to_s + " "
#  string += d.calculated_suggested_fee_cents.to_s + " "
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
Sale.connection.execute("SELECT id FROM sales ORDER BY id ASC LIMIT 20").to_a.map{|x| x['id'].to_i}.each{|x|
  s = Sale.find_by_id(x)
  string = ""
  string += s.id.to_s + " "
  string += s.calculated_total_cents.to_s + " "
  string += s.calculated_subtotal_cents.to_s + " "
  string += s.calculated_discount_cents.to_s + " "
  f.write(string + "\n")
}
f.close

f = File.open("output/gizmo_events", "w")
GizmoEvent.connection.execute("SELECT id FROM gizmo_events ORDER BY id ASC LIMIT 20").to_a.map{|x| x['id'].to_i}.each{|x|
  g = GizmoEvent.find_by_id(x)
  string = ""
  string += g.id.to_s + " "
  string += g.donation_id.to_s + " "
  string += g.sale_id.to_s + " "
  string += g.disbursement_id.to_s + " "
  string += g.recycling_id.to_s + " "
  begin
    string += g.unit_price_cents.to_s + " "
  rescue
    begin
      string += g.adjusted_fee_cents.to_s + " "
    rescue
      string += " "
    end
  end
  begin
    string += g.as_is.to_s + " "
  rescue
    string += " "
  end
  begin
    string += g.description.to_s + " "
  rescue
    string += " "
  end
  begin
    string += g.size.to_s + " "
  rescue
    string += " "
  end
  f.write(string + "\n")
}
f.close
