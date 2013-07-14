class Shift < ActiveRecord::Base
  acts_as_userstamp

  belongs_to :job
  belongs_to :weekday
  belongs_to :worker
  belongs_to :schedule

  def validate
    errors.add("end_time", "is before the start time") unless self.start_time && self.end_time && self.start_time < self.end_time
    errors.add("end_time", "is after 8PM") unless self.end_time && Time.parse(self.end_time.hour.to_s + ":" + self.end_time.min.to_s) <= Time.parse("20:00")
    errors.add("start_time", "is before 8AM") unless self.start_time && Time.parse(self.start_time.hour.to_s + ":" + self.start_time.min.to_s) >= Time.parse("8:00")
  end

  def months_to_s
    "every #{self.repeats_every_months} months, repeating on month of #{self.repeats_on_day}"
  end

  def repeats_on_day
    if defined?(@set_repeats_on_day)
      return @set_repeats_on_day
    end
    add_this = (repeats_on_months - (_calculate_d(Date.today) % repeats_every_months)) % repeats_every_months
    d = Date.today + add_this.months
    Date.new(d.year, d.month, 1)
  end

  def repeats_on_day=(date)
    @set_repeats_on_day = date
  end

  before_save :set_repeats_on_months
  def _calculate_d(d)
    d = Date.parse(d) if d.class == String
    (d.month + (d.year * 12))
  end

  def set_repeats_on_months
    if defined?(@set_repeats_on_day)
      begin
        d = @set_repeats_on_day.class == String ? Date.parse(@set_repeats_on_day): @set_repeats_on_day
        write_attribute(:repeats_on_months, _calculate_d(d) % repeats_every_months) if d
      rescue
      end
    end
  end

  def next_cycle_date
    if self.week.to_s.strip.length == 0
      return ""
    end
    d = Date.today
    d += 1 while d.wday != self.weekday_id
    return ((VolunteerShift.week_for_date(d).upcase == self.week.upcase) ? d : (d + 7)).to_s
  end

  def next_cycle_date=(d)
    self.week = d.to_s.strip.length == 0 ? "" : VolunteerShift.week_for_date(Date.parse(d)).upcase
  end

  before_save :set_standard_shift_if_none
  def set_standard_shift_if_none
    self.type ||= 'StandardShift' if self.class == Shift
  end

  def Shift.and_sql_conds(conds)
    conds + (conds.empty? ? "" : " AND ")
  end

  def Shift.destroy_in_range(start, stop, sql_conditions = '') # work_shifts.
    sql_conditions = Shift.and_sql_conds(sql_conditions)
      # check to see what we will be overwriting:
    sql = "SELECT id FROM work_shifts WHERE shift_date BETWEEN '#{start.to_s}' AND '#{stop.to_s}' AND #{sql_conditions} actual"
      remove = WorkShift.find_by_sql( sql )
      if remove.size > 0
        warning = 'Delete all shifts between #{start.to_s} and #{stop.to_s} (#{remove.size} shifts)?'
        in_clause = Array.new
        remove.each do |shift| 
          in_clause << shift.id
        end
        WorkShift.delete_all "id IN (#{in_clause.join(',')})"
      end
  end

  def Shift.generate(start, stop, sql_conditions = '') # shifts.
    sql_conditions = Shift.and_sql_conds(sql_conditions)
    (start..stop).each do |day|
        # check to see if it's a holiday, if so then skip
      holly = Holiday.is_holiday?(day)
      if holly
          # insert a holiday shift:
      else
          # check to see if the schedule displays on that
          #   weekday, if not then skip
        week_letter = VolunteerShift.week_for_date(day)
        weekday_id = day.strftime( '%w' )
        weekday = Weekday.find(:first, :conditions => ["id = ?", weekday_id])
          # get standard shifts that match the day of week
            #   order by workers.name, start_time
            # ASSUMPTION: 
            #   either the weekday_id is null
            #   or the shift_date is null
        root_sched = Schedule.generate_from
        in_clause = root_sched.in_clause
        if footnote = ShiftFootnote.find_by_schedule_id_and_weekday_id(root_sched.id, weekday_id)
          wsf = WorkShiftFootnote.find_by_date(day) || WorkShiftFootnote.new(:date => day)
          wsf.note = footnote.note
          wsf.save!
        else
          wsf = WorkShiftFootnote.find_by_date(day)
          wsf.destroy if wsf
        end
        where_clause = <<WHERE
        (NOT actual) AND 
        #{sql_conditions}
        ((shifts.effective_date IS NULL OR '#{day}' >= shifts.effective_date)
          AND (shifts.ineffective_date IS NULL OR '#{day}' < shifts.ineffective_date)) AND
         (week IS NULL OR week LIKE ' ' OR week ILIKE '#{week_letter}') AND
        ( 
          ( shifts.shift_date = '#{day}' ) 
            OR
          ( shifts.type IN ('StandardShift','Meeting') AND shifts.schedule_id IN #{in_clause} AND shifts.weekday_id = #{weekday_id} ) 
            OR
          ( shifts.type = 'Unavailability' AND shifts.weekday_id = #{weekday_id} ) 
        )
    
WHERE
            #logger.info 'qqq where_clause: ' + where_clause
        shifts = Shift.find(:all, {
              :conditions => where_clause, 
              :select => 'shifts.*, workers.name', 
              :joins => 'LEFT JOIN workers ON shifts.worker_id = workers.id', 
              :order => 'workers.name, start_time, end_time'} 
            )
        shifts.each do |shift|
          if shift.generates_on_day?(day)
            shift.do_my_generate(day)
          end
        end
      end
      # next
    end
  end

  def generates_on_day?(day)
    raise self.class.to_s
  end

  def save_for_worker?(day, w = self.worker)
    return false unless w
    v = Vacation.find(:first, :conditions => ["worker_id = ? AND ? BETWEEN effective_date AND ineffective_date", w.id, day])
    return true unless v
  end

  def display_name_skedj
    skedj = Thread.current['skedj_obj']
    raise if skedj.nil?
    prepend = ""
    if skedj.opts[:presentation_mode] == "Edit"
      prepend = "[#{self.id}] "
    end
    prepend + display_name
  end

  def display_worker_skedj
    skedj = Thread.current['skedj_obj']
    raise if skedj.nil?
    prepend = ""
    if skedj.opts[:presentation_mode] == "Edit"
      prepend = "[#{self.id}] "
    end
    prepend + self.worker.name
  end

  def display_name
    skedj = Thread.current['skedj_obj']
    s = ""
    #schedule.id != skedj.conditions.schedule_id
    s = " (" + self.week.upcase + ")" if self.week.to_s.strip.length > 0
    self.name + s
  end

  def read_type
    self.read_attribute(:type)
  end

  def skedjul_link_controller
    self.read_type == 'Meeting' ? "meetings" : "shifts"
  end

  def has_copy
    !(self.read_type == 'Meeting')
  end

    def skedj_style(overlap, last)
      shift_style = ""
      if self.read_type == 'Meeting'
        shift_style = 'meeting'
      elsif self.read_type == 'Unavailability'
        shift_style = 'unavailable'
      elsif self.worker_id == 0
        shift_style = 'unfilled'
      elsif overlap
        shift_style = 'hardconflict'
      else
        shift_style = self.proposed ? 'proposed' : self.training ? 'training' : 'shift'
      end
      return shift_style
    end
end
