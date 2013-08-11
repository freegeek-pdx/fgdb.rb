class VolunteerEvent < ActiveRecord::Base
  attr_accessor :redirect_to
  validates_presence_of :date
  has_many :volunteer_shifts, :dependent => :destroy
  has_many :resources_volunteer_events, :dependent => :destroy
  validates_associated :volunteer_shifts

  def date_anchor
    self.date.strftime('%Y%m%d')
  end

  def to_s
    description
  end

  def time_range_s
    return '0-0' if self.volunteer_shifts.length == 0
    my_start_time = self.volunteer_shifts.sort_by(&:start_time).first.start_time
    my_end_time = self.volunteer_shifts.sort_by(&:end_time).last.end_time
    (my_start_time.strftime("%I:%M") + ' - ' + my_end_time.strftime("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "")
  end

  def merge_similar_shifts
      hash = {}
      self.volunteer_shifts.each{|y|
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
              if ((first.end_time == second.start_time) or (first.start_time == second.end_time)) and (first.slot_number == second.slot_number)
                first.start_time = [first.start_time, second.start_time].min
                first.end_time = [first.end_time, second.end_time].max
                combine = true
              end
              if combine
                first.assignments << second.assignments
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

  def copy_to(date, time_shift, copy_for)
    new = self.class.new(self.attributes)
    assigns = []
    new.volunteer_shifts = self.volunteer_shifts.map{|x|
      n = x.class.new(x.attributes); n.time_shift(time_shift);
      if copy_for.include?(n.volunteer_task_type_id)
        x.assignments.select{|x| x.contact_id && (!x.cancelled?)}.each do |y|
          a = y.class.new(y.attributes)
          a.time_shift(time_shift)
          a.call_status_type_id = nil
          a.attendance_type_id = nil
          a.volunteer_shift = n
          assigns << a
        end
      end
      n
    }
    new.resources_volunteer_events = self.resources_volunteer_events.map{|x| x.class.new(x.attributes)}
    new.date = date
    new.resources_volunteer_events.each{|x| x.time_shift(time_shift)}
    conflictors = assigns.select{|x| x.internal_date_hack_value = date; (!x.contact.nil?) && (!x.contact.is_organization) && x.find_overlappers(:for_contact).length > 0}
    if conflictors.length == 0
      new.save!
      new.volunteer_shifts.each{|x| x.save!}
      assigns.each{|x| x.save!}
      return new
    else
      new.destroy if new.id
      return conflictors
    end
  end
end
