class ResourcesVolunteerDefaultEvent < ActiveRecord::Base
  belongs_to :resource
  belongs_to :volunteer_default_event

  def skedj_style(overlap, last)
    overlap ? 'hardconflict' : 'shift'
  end

  def display
    time_range_s + ": " + self.volunteer_default_event.to_s
  end

  def time_range_s
    (self.my_start_time("%I:%M") + ' - ' + self.my_end_time("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "")
  end

  def ResourcesVolunteerDefaultEvent.find_conflicts(startd, endd, gconditions = nil)
    gconditions ||= Conditions.new
    vs_conds = gconditions.dup
    vs_conds.empty_enabled = "false"

    vs_conds.date_enabled = "true"
    vs_conds.date_date_type = 'arbitrary'
    vs_conds.date_start_date = startd.to_s
    vs_conds.date_end_date = endd.to_s

    matches = ResourcesVolunteerEvent.find(:all, :conditions => vs_conds.conditions(ResourcesVolunteerEvent), :include => [:volunteer_event])
  end

  def ResourcesVolunteerDefaultEvent.generate(start_date, end_date, gconditions = nil)
    if gconditions
      gconditions = gconditions.dup
      gconditions.empty_enabled = "false"
    else
      gconditions = Conditions.new
    end
    (start_date..end_date).each{|x|
      next if Holiday.is_holiday?(x)
      w = Weekday.find(x.wday)
      next if !w.is_open
      ds_conds = gconditions.dup
      ds_conds.effective_at_enabled = "true"
      ds_conds.effective_at = x
      ds_conds.weekday_enabled = "true"
      ds_conds.weekday_id = w.id
      shifts = ResourcesVolunteerDefaultEvent.find(:all, :conditions => ds_conds.conditions(ResourcesVolunteerDefaultEvent), :include => [:volunteer_default_event])
      shifts.each{|ds|
        ve = VolunteerEvent.find(:all, :conditions => ["volunteer_default_event_id = ? AND date = ?", ds.volunteer_default_event_id, x]).first
        if !ve
          ve = VolunteerEvent.new
          ve.volunteer_default_event_id = ds.volunteer_default_event_id
          ve.date = x
        end
        ve.description = ds.volunteer_default_event.description
        ve.notes = ds.volunteer_default_event.notes
        ve.save!

        s = ResourcesVolunteerEvent.new()
        s.resources_volunteer_default_event_id = ds.id
        s.volunteer_event_id = ve.id
        s.resource_id = ds.resource_id
        s.send(:write_attribute, :start_time, ds.start_time)
        s.send(:write_attribute, :end_time, ds.end_time)
        s.roster_id = ds.roster_id
        s.save!
      }
    }
  end

  def my_start_time(format = "%H:%M")
    read_attribute(:start_time).strftime(format)
  end

  def my_start_time=(str)
    write_attribute(:start_time, VolunteerShift._parse_time(str))
  end

  def my_end_time(format = "%H:%M")
    read_attribute(:end_time).strftime(format)
  end

  def my_end_time=(str)
    write_attribute(:end_time, VolunteerShift._parse_time(str))
  end
end
