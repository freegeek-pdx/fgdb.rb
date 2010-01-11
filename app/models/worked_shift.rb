class WorkedShift < ActiveRecord::Base
  belongs_to :job
  def program
    job.program
  end

  def wc_category
    job.wc_category
  end

  def income_stream
    job.income_stream
  end

  def self.find_by_conditions(conditions)
    list = [:income_stream, :wc_category, :program]
    to_select = list.inject(""){|t,x| t += ", #{x.to_s.pluralize}.description AS #{x}"}
    to_join = list.inject(""){|t,x| t += " LEFT OUTER JOIN #{x.to_s.pluralize} ON #{x.to_s.pluralize}.id = jobs.#{x}_id"}
    connection.execute("SELECT worked_shifts.duration AS duration, jobs.name AS job #{to_select} FROM worked_shifts LEFT OUTER JOIN jobs ON jobs.id = worked_shifts.job_id #{to_join} WHERE #{sanitize_sql_for_conditions(conditions)}")
  end
end
