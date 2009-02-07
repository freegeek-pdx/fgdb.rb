class CoverageType < ActiveRecord::Base
  has_many :jobs
  has_many :standard_shifts
  has_many :work_shifts
end
