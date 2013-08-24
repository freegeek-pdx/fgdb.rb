intern_titles = {
  "Build Instructors" => "BETA",
  "Prebuild Interns" => "BETA",
  "Hardware Grants Interns" => "Hardware Grants",
  "Printers Interns" => "Printers",
  "Recycling Interns" => "Recycling",
  "Sorting Interns" => "Sorting",
  "Tech Support Interns" => "Tech Support",
  "Thrift Store Interns" => "Sales",
  "Front Desk Interns" => "Front Desk",
  "Misc" => "Admin",
  "Getting Started Classes" => "Education"
}

contact_cache = {}
contact_list = Hash.new()

intern_titles.keys.each do |rname|
  r = Roster.find_by_name rname
  title = intern_titles[rname]
  raise "No #{rname} roster" unless r
  people = r.volunteer_default_shifts.map{|y| y.default_assignments.assigned.map{|x| x.contact}}.flatten
  people.each do |person|
    unless contact_cache.keys.include?(person.id)
      contact_cache[person.id] = person
      contact_list[person.id] = []
    end
    contact_list[person.id] << title unless contact_list[person.id].include?(title)
  end
end

contact_cache.keys.each do |person_id|
  person = contact_cache[person_id]
  titles = contact_list[person_id]
  title = titles.sort.join(" & ")
  unless person.volunteer_intern_title
    person.volunteer_intern_title = title
    person.save
    puts person.display_name + " is now a " + title + " intern"
  end
end
