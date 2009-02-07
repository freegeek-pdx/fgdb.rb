class Holiday < ActiveRecord::Base
  belongs_to :weekday
  belongs_to :schedule
  belongs_to :frequency_type
end
