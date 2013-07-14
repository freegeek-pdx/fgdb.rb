#!/usr/bin/ruby

# Api's we will use:
## http://wiki.civicrm.org/confluence/display/CRMDOC33/Contact+APIs
## http://wiki.civicrm.org/confluence/display/CRMDOC33/Contribution+APIs

# API explorer: http://civicrm/drupal/?q=civicrm/ajax/doc#explorer

require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require File.dirname(__FILE__) + '/../config/boot'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

$civicrm_mode = true

STATES =  states = {
"Alabama" => "AL",
"Alaska" => "AK",
"Arizona" => "AZ",
"Arkansas" => "AR",
"California" => "CA",
"Colorado" => "CO",
"Connecticut" => "CT",
"Delaware" => "DE",
"Florida" => "FL",
"Georgia" => "GA",
"Hawaii" => "HI",
"Idaho" => "ID",
"Illinois" => "IL",
"Indiana" => "IN",
"Iowa" => "IA",
"Kansas" => "KS",
"Kentucky" => "KY",
"Louisiana" => "LA",
"Maine" => "ME",
"Maryland" => "MD",
"Massachusetts" => "MA",
"Michigan" => "MI",
"Minnesota" => "MN",
"Mississippi" => "MS",
"Missouri" => "MO",
"Montana" => "MT",
"Nebraska" => "NE",
"Nevada" => "NV",
"New Hampshire" => "NH",
"New Jersey" => "NJ",
"New Mexico" => "NM",
"New York" => "NY",
"North Carolina" => "NC",
"North Dakota" => "ND",
"Ohio" => "OH",
"Oklahoma" => "OK",
"Oregon" => "OR",
"Pennsylvania" => "PA",
"Rhode Island" => "RI",
"South Carolina" => "SC",
"South Dakota" => "SD",
"Tennessee" => "TN",
"Texas" => "TX",
"Utah" => "UT",
"Vermont" => "VT",
"Virginia" => "VA",
"Washington" => "WA",
"West Virginia" => "WV",
"Wisconsin" => "WI",
  "Wyoming" => "WY"}

class Hash
  def r_to_params
    self.map{|k,v| "#{k.to_s}=#{CGI.escape(v.to_s)}"}.join("&")
  end
end

class CiviCRMClient
  def CiviCRMClient.from_defaults
    CiviCRMClient.new(Default['civicrm_server'], Default['civicrm_api_key'], Default['civicrm_user_key'])
  end

  def initialize(server, api_key, user_key)
    @server = server
    @site_key = api_key
    @key = user_key
  end

  def server
    @server + "/drupal"
  end

  #               ex: "fgdb_donations" "fgdb_donation_id"

  def custom_field_id(group_name, field_name)
    res = self.do_req("civicrm/CustomField/get", "")
    hash = {}
    res["values"].each{|k,v|
      hash[v["name"]] = k
    }
    return hash[field_name.gsub(/ /, "_")]
  end

  def fgdb_field(table_name)
    custom_field_id("FGDB #{table_name.humanize} Information", "FGDB #{table_name.humanize} ID")
  end

  def do_req(func, opts = {}, version = 3)
    opts = opts.r_to_params if opts.class == Hash
    url = "http://#{server}/sites/all/modules/civicrm/extern/rest.php?version=#{version}&q=#{func}&json=1&key=#{@site_key}&api_key=#{@key}&#{opts}"
    if func.match(/get$/)
      get(url)
    else
      post(url)
    end
  end

  private
  def post(url)
    url = URI.parse(url)
    req = Net::HTTP::Post.new(url.request_uri)
    ret = Net::HTTP.start(url.host, url.port) {|http| http.request(req)}
    ret = JSON.parse(ret.body)
    raise ret["error_message"] if ret.class == Hash and ret["is_error"] == 1
    ret
  end

  def get(url)
    ret = JSON.parse(Net::HTTP.get(URI.parse(url)))
    raise ret["error_message"] if ret.class == Hash and ret["is_error"] == 1
    ret
  end
end

def sync_donation_from_fgdb(fgdb_id)
  civicrm_id = nil
  civicrm_id = 1
  return civicrm_id
end

def sync_donation_from_civicrm(civicrm_id)
  fgdb_id = nil
  fgdb_id = 1
  return fgdb_id
end


class ContactObject
  attr_accessor :is_organization, :organization
  attr_accessor :first_name, :middle_name, :last_name

  attr_accessor :address, :address_extra, :city, :state, :postal_code, :country
  attr_accessor :phone_numbers
  attr_accessor :emails

  attr_accessor :notes, :birthday

  def contact_type
    is_organization ? "Organization" : "Individual"
  end

  def to_fgdb(c)
    c.created_by ||= 1
    c.is_organization = is_organization 
    c.organization = organization 

    c.first_name = first_name 
    c.middle_name = middle_name 
    c.surname = last_name 

    c.address = self.address
    c.extra_address = self.address_extra
    c.city = self.city
    c.state_or_province = self.state
    c.postal_code = self.postal_code
    c.country = self.country

    cmeth = []
    # TODO: could handle this better, no need to delete/recreate, find existing if match
    self.emails.each do |x|
      cmeth << ContactMethod.new(:contact_method_type => ContactMethodType.find_by_name(x.first), :value => x.last)
    end
    self.phone_numbers.each do |x|
      cmeth << ContactMethod.new(:contact_method_type => ContactMethodType.find_by_name(x.first), :value => x.last)
    end
    puts cmeth.inspect

    c.contact_methods = cmeth
    c.notes = notes
    c.birthday = self.birthday
  end

  def from_fgdb(c)
    self.is_organization = c.is_organization
    self.organization = c.organization

    self.first_name = c.first_name
    self.middle_name = c.middle_name
    self.last_name = c.surname

    self.address = c.address
    self.address_extra = c.extra_address
    self.city = c.city
    self.state = c.state_or_province
    self.postal_code = c.postal_code
    self.country = c.country

    self.emails = []
    self.phone_numbers = []
    c.contact_methods.each do |cm|
      location = 'Other'
      mytype = cm.contact_method_type.name
      if mytype.match(/home/)
        location = 'Home'
      elsif mytype.match(/work/)
        location = 'Work'
      end

      if mytype.match(/email/)
        self.emails << [location, cm.value]
      elsif mytype.match(/liason/)
        nil
      else
        phone_type = 'Phone'
        if mytype.match(/cell/)
          phone_type = 'Mobile'
        elsif mytype.match(/fax/)
          phone_type = 'Fax'
        elsif mytype.match(/ip/)
          phone_type = 'IP'
        elsif mytype.match(/emergency/)
          phone_type = 'Emergency'
        end
        self.phone_numbers << [location, phone_type, cm.value]
      end
    end

    self.birthday = c.birthday
    self.notes = c.notes
  end

  def getoptions(c, tbl, field)
    h = {}
    c.do_req("civicrm/#{tbl}/getoptions", {"field" => field})["values"].each do |k, v|
      h[k] = v
    end
    return h
  end

  def by_name(h)
    newh = {}
    h.each do |k, v|
      newh[v] = k
    end
    return newh
  end

  def from_civicrm(my_client, civicrm_id)
    civicrm_contact = my_client.do_req("civicrm/contact/get", {"contact_id" => civicrm_id})["values"][civicrm_id]
  puts my_client.do_req("civicrm/entity_tag/get", {"contact_id" => civicrm_id}).inspect # will need to create/delete if needed
    my_notes = my_client.do_req("civicrm/note/get", {"entity_table" => "civicrm_contact", "entity_id" => civicrm_id, "subject" => "FGDB"})["values"]  # delete, then re-create it
    if my_notes.length > 0
      self.notes = my_notes.values.first["note"]
    else
      self.notes = ""
    end

    self.is_organization = civicrm_contact["contact_type"] == "Organization"
    self.organization = civicrm_contact["organization_name"]

    self.first_name = civicrm_contact["first_name"]
    self.middle_name = civicrm_contact["middle_name"]
    self.last_name = civicrm_contact["last_name"]

    loc_map = {"Home" => "home", "Work" => "work"}
    loc_by_id = getoptions(my_client, "phone", "location_type_id")
    c_map = {"Mobile" => "cell phone", "IP" => "ip phone", "Emergency" => "emergency phone", "Fax" => "fax"}
    phone_by_id = getoptions(my_client, "phone", "phone_type_id")

    self.phone_numbers = []
    phones = my_client.do_req("civicrm/phone/get", {:contact_id => civicrm_id})["values"]
    if phones.length > 0
      phones.values.each do |x|
        loc = loc_by_id[x["location_type_id"]]
        ptype = phone_by_id[x["phone_type_id"]]
        value = x["phone"]
        
        c_type = c_map[ptype] || 'phone'
        if ["fax", "phone"].include?(c_type)
          add_to = loc_map[loc]
          c_type = add_to + " " + c_type if add_to
          self.phone_numbers << [c_type, value]
        end
      end
    end

    self.emails = []
    emails = my_client.do_req("civicrm/email/get", {:contact_id => civicrm_id})["values"]
    if emails.length > 0
      emails.values.each do |x|
        location_type = loc_by_id[x["location_type_id"]]
        value = x["email"]
        c_type = [loc_map[location_type], "email"].select{|x| !!x}.join(" ")
        self.emails << [c_type, value]
        # Contact.method.find
      end
    end

    self.birthday = civicrm_contact["birth_date"]

    self.address = civicrm_contact["street_address"]
    self.address_extra = civicrm_contact["supplemental_address_1"]
    self.city = civicrm_contact["city"]
    self.state = civicrm_contact["state_province_name"]
    self.country = civicrm_contact["country"]
    self.postal_code = civicrm_contact["postal_code"]
  end

  def to_civicrm
    hash = {}
    hash[:contact_type] = contact_type
    hash[:organization_name] = organization

    hash[:first_name] = first_name
    hash[:middle_name] = middle_name
    hash[:last_name] = last_name

    hash["birth_date"] = birthday
    return hash
  end

  def to_civicrm_extras(my_client, civicrm_id)
    my_notes = my_client.do_req("civicrm/note/get", {"entity_table" => "civicrm_contact", "entity_id" => civicrm_id, "subject" => "FGDB"})["values"] 
    my_notes.to_a.map(&:last).each do |n|
      my_client.do_req("civicrm/note/delete", {:id => n["id"]})
    end

    # TODO: Date.today should be something else/
    if self.notes && self.notes.length > 0
      my_client.do_req("civicrm/note/create", {"entity_table" => "civicrm_contact", "entity_id" => civicrm_id, "subject" => "FGDB", 'modified_date' => Date.today, 'note' => self.notes})["values"]
    end

    location_types = by_name(getoptions(my_client, "phone", "location_type_id"))
    phone_types = by_name(getoptions(my_client, "phone", "phone_type_id"))

    my_phones = my_client.do_req("civicrm/phone/get", {"contact_id" => civicrm_id})["values"] 
    my_phones.to_a.map(&:last).each do |n|
      my_client.do_req("civicrm/phone/delete", {:id => n["id"]})
    end

    my_addresss = my_client.do_req("civicrm/address/get", {"contact_id" => civicrm_id})["values"] 
    my_addresss.to_a.map(&:last).each do |n|
      my_client.do_req("civicrm/address/delete", {:id => n["id"]})
    end

    my_emails = my_client.do_req("civicrm/email/get", {"contact_id" => civicrm_id})["values"] 
    my_emails.to_a.map(&:last).each do |n|
      my_client.do_req("civicrm/email/delete", {:id => n["id"]})
    end

    self.emails.each do |loc, email|
      my_client.do_req("civicrm/email/create", {"contact_id" => civicrm_id, "email" => email, "location_type_id" => location_types[loc]})
    end

    self.phone_numbers.each do |loc, ptype, phone|
      my_client.do_req("civicrm/phone/create", {"contact_id" => civicrm_id, "phone" => phone, "location_type_id" => location_types[loc], "phone_type_id" => phone_types[loc]})
    end

    if (self.address && self.address.length >= 0) or (self.city && self.city.length >= 0) or (self.postal_code && self.postal_code.length >= 0)
      ahash = {"contact_id" => civicrm_id, "location_type_id" => location_types['Other']}
      ahash["street_address"] = self.address
      ahash["supplemental_address_1"] = self.address_extra
      ahash["city"] = self.city

      state_lookup = by_name(STATES)
      civi_lookup = by_name(getoptions(my_client, 'address', 'state_province_id'))
      state_lookup.keys.each do |k|
        state_lookup[k] = civi_lookup[state_lookup[k]]
      end
      civi_lookup.each {|k, v|
        state_lookup[k.upcase] = v
      }
      ahash["state_province_id"] = state_lookup[self.state.upcase].to_i
      ahash["country"] = self.country
      ahash["postal_code"] = self.postal_code.strip
      my_client.do_req("civicrm/address/create", ahash)
    end
  end
end

def sync_contact_from_fgdb(fgdb_id)
  civicrm_id = nil
  my_client = CiviCRMClient.from_defaults
  my_custom = my_client.fgdb_field("contact")
  find_arr = my_client.do_req("civicrm/contact/get", "custom_#{my_custom}=#{fgdb_id}")
  civicrm_id = (find_arr["count"] == 1) ? find_arr["id"] : nil

  c = Contact.find_by_id(fgdb_id)
  return nil unless c
  co = ContactObject.new
  co.from_fgdb(c)
  hash = co.to_civicrm

  if civicrm_id
    hash[:id] = civicrm_id
    # TODO: return nil for FAIL if not success
    my_client.do_req("civicrm/contact/update", hash)
  else
    hash["custom_#{my_custom}"] = fgdb_id
    ret = my_client.do_req("civicrm/contact/create", hash)
    civicrm_id = ret["id"]
  end
  co.to_civicrm_extras(my_client, civicrm_id)

  return civicrm_id
end

def sync_contact_from_civicrm(civicrm_id)
  fgdb_id = nil
  my_client = CiviCRMClient.from_defaults
  my_custom = my_client.fgdb_field("contact")
  ret_values = my_client.do_req("civicrm/contact/get", {"contact_id" => civicrm_id, "return" => "custom_#{my_custom}"})["values"]
  return nil if ret_values.length == 0
  fgdb_id = ret_values.length > 0 ? ret_values[civicrm_id]["custom_#{my_custom}"].to_i : nil

  co = ContactObject.new
  co.from_civicrm(my_client, civicrm_id)

  c = nil
  unless fgdb_id and false and (c = Contact.find_by_id(fgdb_id))
    fgdb_id = nil
    @saved_civicrm = true
    c = Contact.new
  end

  co.to_fgdb(c)
  c.save!
  if @saved_civicrm
    fgdb_id = c.id
    my_client.do_req("civicrm/contact/update", {:id => civicrm_id, :contact_type => civicrm_contact["contact_type"], "custom_#{my_custom}" => fgdb_id})
  end
  return fgdb_id
end

def do_sync(source, table, tid)
  if source == "civicrm" && (ENV["SCRIPT"] && system(ENV["SCRIPT"], "find", "skip_civicrm", table, tid))
    system(ENV["SCRIPT"], "rm", source, table, tid) or raise Exception
    system(ENV["SCRIPT"], "rm", "skip_civicrm", table, tid) or raise Exception
    return
  else
    puts "Syncing #{table} ##{tid} from #{source} at #{Time.now}"
    if source == "fgdb"
      fgdb_id = tid
      success = !!(oid = civicrm_id = (table == "donations" ? sync_donation_from_fgdb(fgdb_id) : sync_contact_from_fgdb(fgdb_id)))
    else #source == "civicrm"
      civicrm_id = tid
      success = !!(oid = fgdb_id = (table == "donations" ? sync_donation_from_civicrm(civicrm_id) : sync_contact_from_civicrm(civicrm_id)))
    end
    puts "  Completed at #{Time.now}. Resulting id on #{source == "fgdb" ? "civicrm" : "fgdb"} was: #{oid.nil? ? "FAIL" : oid}"
  end
end

def do_main
  success = false
  fgdb_id = nil
  civicrm_id = nil
  raise ArgumentError unless ARGV.length == 3
  source, table, tid = ARGV
  raise ArgumentError unless tid.to_i != 0
  raise ArgumentError unless ["fgdb", "civicrm"].include?(source)
  raise ArgumentError unless ["contacts"].include?(table)
  @saved_civicrm = false

  do_sync(source, table, tid)

  if ENV["SCRIPT"]
  if success
    system(ENV["SCRIPT"], "rm", source, table, tid) or raise Exception
    if source == "civicrm"
      system(ENV["SCRIPT"], "rm", "fgdb", table, fgdb_id.to_s) or raise Exception
      if @saved_civicrm
        system(ENV["SCRIPT"], "add", "skip_civicrm", table, civicrm_id.to_s) or raise Exception
      end
    else # source == "fgdb"
      system(ENV["SCRIPT"], "add", "skip_civicrm", table, civicrm_id.to_s) or raise Exception
    end
  else
    system(ENV["SCRIPT"], "take_a_break") or raise Exception
  end
  end
  return success
end

if $0 == __FILE__
  exit(do_main)
end

