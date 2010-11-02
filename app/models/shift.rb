class Shift < ActiveRecord::Base
  belongs_to :job, :include => [:coverage_type]
  belongs_to :weekday
  belongs_to :worker
  belongs_to :coverage_type
end
