class VolunteerTaskType < ActiveRecord::Base
  belongs_to :program

  def to_s
    description
  end

  named_scope :instantiables, { :conditions => {'instantiable' => true} }

  named_scope :effective_on, lambda { |date|
    { :conditions => ['(effective_on IS NULL OR effective_on <= ?) AND (ineffective_on IS NULL OR ineffective_on > ?)', date, date] }
  }

  def self.find_actual(*ids)
    ids.delete_if {|id| id == 0 }
    find(*ids)
  end

  def display_name
    disp = self.description
    if program.name != "other"
      disp << " (" + program.display_name + ")"
    end
    return disp
  end
end
