class Job < ActiveRecord::Base
  has_many :standard_shifts
  has_many :work_shifts
  has_and_belongs_to_many :workers
  belongs_to :coverage_type
end
