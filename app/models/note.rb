class Note < ActiveRecord::Base
  include PrintmeHelper

  belongs_to :system
  belongs_to :contact
  validates_existence_of :system
  validates_existence_of :contact

  attr_accessor :lshw_output

  before_save :set_system

  def set_system
    if !self.system
      parse_stuff(@lshw_output)

      found_system = find_system_id
      if found_system
        self.system = System.find_by_id(found_system)
      else
        self.system = System.new
        system.system_model  = @system_model
        system.system_serial_number  = @system_serial_number
        system.system_vendor  = @system_vendor
        system.mobo_model  = @mobo_model
        system.mobo_serial_number  = @mobo_serial_number
        system.mobo_vendor  = @mobo_vendor
        system.model  = @model
        system.serial_number  = @serial_number
        system.vendor  = @vendor
      end
    end
  end
end
