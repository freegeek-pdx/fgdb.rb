class Roster < ActiveRecord::Base
  has_and_belongs_to_many :skeds
  belongs_to :contact_type
  named_scope :enabled, :conditions =>  ['enabled = ?', true]
  has_many :volunteer_shifts
  has_many :volunteer_default_shifts
  belongs_to :restrict_from_sked, :class_name => "Sked"

  def sandbox?
    name.downcase == 'sandbox'
  end

  def Roster.auto_generate_all
    fails = []
    if Roster.are_auto_generated?
      Roster.enabled.reject(&:sandbox?).each do |r|
        start_d = r.generated_to_date + 1
        end_d = Date.today + eval(Default["autogenerate_volskedj_out"])
        fails = fails + r.auto_generate(start_d, end_d) if start_d <= end_d
      end
    end
    return fails
  end

  def generated_to?(d)
    generated_to_date >= d
  end

  def to_s
    name
  end

  def generated_to_date
    newc = Conditions.new
    newc.apply_conditions({})
    newc.roster_enabled = true
    newc.roster_id = self.id
    newc.generated_shift_enabled = true
    d1 = VolunteerEvent.maximum(:date, :conditions => newc.conditions(Assignment), :joins => 'INNER JOIN "volunteer_shifts" ON volunteer_shifts.volunteer_event_id = volunteer_events.id INNER JOIN "assignments" ON assignments.volunteer_shift_id = volunteer_shifts.id LEFT OUTER JOIN "attendance_types" ON "attendance_types".id = "assignments".attendance_type_id')
    d2 = VolunteerEvent.maximum(:date, :conditions => newc.conditions(ResourcesVolunteerEvent), :joins => 'INNER JOIN "resources_volunteer_events" ON resources_volunteer_events.volunteer_event_id = volunteer_events.id') 
    return [d1, d2, Date.today].select{|x| !!x}.max
  end

  def auto_generate(from, to)
    results = []
    begin
      c = Conditions.new
      c.apply_conditions({})
      c.roster_enabled = true
      c.roster_id = self.id
      conflicts = VolunteerDefaultShift.find_conflicting_assignments(from, to, c)
      skippers = conflicts.map{|x| x[1].id}
      results = conflicts.map{|x| "On #{x[0]}, #{x[1].contact.display_name} (##{x[1].contact_id}) was not successfully scheduled for #{x[1].slot_type_desc} (#{self.name} roster) as they have the following conflicting shifts: #{x[2].map{|x| x.description}.join(" ")}"}
      VolunteerDefaultShift.generate(from, to, c, skippers)
      ResourcesVolunteerDefaultEvent.generate(from, to, c)
    rescue => e
      puts "ERROR: Failed to generate #{self.name} roster!"
      puts "Please check for consistency, error message: #{e.to_s}"
    end
    return results
  end

  def Roster.are_auto_generated?
    ! Default["autogenerate_volskedj_out"].nil?
  end

  def skeds_s
    self.skeds.map(&:name).sort.join(", ")
  end

  def vol_event_for_date(date)
    VolunteerEvent.find_or_create_by_description_and_date("Roster ##{self.id}", date)
  end

  def vol_event_for_weekday(wday)
    VolunteerDefaultEvent.find_or_create_by_description_and_weekday_id("Roster ##{self.id}", wday)
  end
end
