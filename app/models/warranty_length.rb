class WarrantyLength < ActiveRecord::Base
  validates_presence_of :system_type
  validates_presence_of :length
  validates_presence_of :box_source

  named_scope :effective_on, lambda { |date|
    { :conditions => ['(effective_on IS NULL OR effective_on <= ?) AND (ineffective_on IS NULL OR ineffective_on > ?)', date, date] }
  }

  validates_numericality_of :length_number
  validates_presence_of :length_unit

  def self.custom_option_selects
    [:system_type, :box_source, :os_type]
  end

  def self.custom_options_for(opt)
    h = ApplicationController.new.send(:_parse_metadata_wo)
    q = {:system_type => h["Type of Box"], :box_source => h["Box source"], :os_type => WorkOrdersController::OS_OPTIONS}
    return q[opt]
  end

  def self.type_override_for(opt)
    return {:length => "date_period_length"}[opt]
  end

  def length_number
    read_attribute(:length).to_s.split(".")[0].to_s
  end

  attr_accessor :length_number_before_type_cast
  def length_number=(setting)
    @length_number_before_type_cast = setting
    self.length = setting.to_i.to_s + "." + length_unit
  end

  def length_unit=(setting)
    self.length = length_number + "." + UNITS.select{|x| x.to_s.match(setting)}.first.to_s
  end

  UNITS = [:years, :months, :days]

  def length
    eval_length.inspect
  end

  def length_unit
    read_attribute(:length).to_s.split(".")[1].to_s.pluralize
  end

  def self.find_warranty_for(date_out, system_type, box_source, os_type = nil)
    WarrantyLength.effective_on(date_out).select{|x| x.system_type == system_type && x.box_source == box_source && (x.os_type.to_s.empty? || os_type.to_s == x.os_type.to_s)}.first
  end

  def is_in_warranty(date)
    ends_at = date + eval_length
    ends_at >= Date.today
  end

  def eval_length
    if length_number.length > 0 && length_unit.length > 0
      eval(read_attribute(:length))
    else
      nil
    end
  end
end
