class TillAdjustment < ActiveRecord::Base
  define_amount_methods_on("adjustment")
  belongs_to :till_type
  validates_existence_of :till_type
  validates_presence_of :till_date
  validates_presence_of :till_type_id
end

