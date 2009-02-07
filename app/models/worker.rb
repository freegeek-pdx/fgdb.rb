class Worker < ActiveRecord::Base
  has_many :standard_shifts
  has_and_belongs_to_many :jobs
  belongs_to :worker_type
  has_and_belongs_to_many :meetings
  has_many :work_shifts
  has_many :vacations

  def is_available?( shift = Workshift.new )
    true
  end
end
