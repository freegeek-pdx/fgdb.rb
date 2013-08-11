class VolunteerDefaultEvent < ActiveRecord::Base
  attr_accessor :redirect_to
  validates_presence_of :weekday_id
  belongs_to :weekday
  has_many :volunteer_default_shifts, :dependent => :destroy
  has_many :resources_volunteer_default_events, :dependent => :destroy
  validates_associated :volunteer_default_shifts

  def to_s
    description
  end

  def validate
    errors.add('next_cycle_date', 'cannot be set on a roster event') if self.week and self.week.length > 1 and self.description.match(/Roster #/)
  end

  def next_cycle_date
    if self.week.to_s.strip.length == 0
      return ""
    end
    d = Date.today
    d += 1 while d.wday != self.weekday_id if self.weekday_id
    return ((VolunteerShift.week_for_date(d).upcase == self.week.upcase) ? d : (d + 7)).to_s
  end

  def next_cycle_date=(d)
    self.week = d.to_s.strip.length == 0 ? "" : VolunteerShift.week_for_date(Date.parse(d)).upcase
  end

  def merge_similar_shifts
      hash = {}
      self.volunteer_default_shifts.each{|y|
        k = (y.volunteer_task_type_id.to_s || "0") + "-" + (y.description || "")
        hash[k] ||= []
        hash[k] << y
      }
      hash.each{|k, v|
        prev_length = 0
        length = v.length
        while length != prev_length
          v.each{|first|
            v.each{|second|
              next if first.id == second.id
              combine = false
              if ((first.end_time == second.start_time) or (first.start_time == second.end_time)) and (first.slot_count == second.slot_count)
                first.start_time = [first.start_time, second.start_time].min
                first.end_time = [first.end_time, second.end_time].max
                combine = true
              end
              if (!combine) and (first.end_time == second.end_time) and (second.start_time == first.start_time)
                second.default_assignments = second.default_assignments.map{|x| x.slot_number += first.slot_count; x}
                first.slot_count += second.slot_count
                combine = true
              end
              if combine
                first.default_assignments << second.default_assignments
                second.destroy
                v.delete(second)
                first.save!
                break
              end
            }
          }
          prev_length = length
          length = v.length
        end
      }
  end

  def time_range_s
    my_start_time = self.volunteer_default_shifts.sort_by(&:start_time).first.start_time
    my_end_time = self.volunteer_default_shifts.sort_by(&:end_time).last.end_time
    (my_start_time.strftime("%I:%M") + ' - ' + my_end_time.strftime("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "")
  end

  def copy_to(weekday, time_shift)
    new = self.class.new(self.attributes)
    new.volunteer_default_shifts = self.volunteer_default_shifts.map{|x| x.class.new(x.attributes)}
#    new.resources = self.resources.map{|x| x.class.new(x.attributes)}
    new.weekday = weekday
    new.volunteer_default_shifts.each{|x| x.time_shift(time_shift)}
#    new.resources.each{|x| x.time_shift(time_shift)}
    new.save!
    new.volunteer_default_shifts.each{|x| x.save!}
    return new
  end
end
