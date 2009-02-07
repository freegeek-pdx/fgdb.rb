class FrequencyType < ActiveRecord::Base
  has_many :standard_shifts
  has_many :holidays
  has_many :meetings
end
