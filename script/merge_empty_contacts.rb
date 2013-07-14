#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require File.dirname(__FILE__) + '/../config/environment'

$civicrm_mode = true

records = DB.exec("SELECT id FROM contacts WHERE first_name IS NULL AND surname IS NULL AND middle_name IS NULL AND organization IS NULL AND postal_code LIKE '00000';").to_a.map(&:values).map(&:first).map(&:to_i).sort
first = Contact.find(records.shift)
puts "Master record: ##{first.id}"
records.each_with_index do |r_i, i|
  r = Contact.find(r_i)
  puts "Merging record (#{i}/#{records.length}, #{100*i/records.length.to_f}%): ##{r.id}"
  first.merge_these_in([r])
end
