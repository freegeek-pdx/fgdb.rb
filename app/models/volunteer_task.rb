class VolunteerTask < ActiveRecord::Base
  acts_as_userstamp

  belongs_to :volunteer_task_type
  belongs_to :contact
  belongs_to :community_service_type
  belongs_to :program

  validates_presence_of :contact
  validates_presence_of :volunteer_task_type
  validates_presence_of :date_performed
  validates_presence_of :duration
  validates_presence_of :program

  before_save :add_contact_types

  def self.find_by_conditions(conditions)
    connection.execute("SELECT volunteer_tasks.duration AS duration, community_service_types.description AS community_service_type, volunteer_task_types.description AS volunteer_task_types FROM volunteer_tasks LEFT OUTER JOIN volunteer_task_types ON volunteer_task_types.id = volunteer_tasks.volunteer_task_type_id LEFT OUTER JOIN community_service_types ON community_service_types.id = volunteer_tasks.community_service_type_id WHERE #{sanitize_sql_for_conditions(conditions)}")
  end

  def show_for_me
    VolunteerTaskType.instantiables.effective_on(self.date_performed || Date.today).sort_by{|x| x.description.downcase}
  end

  def validate
    if contact.nil?
      errors.add(:contact_id, "must be choosen")
    end
    if duration.to_f <= 0.0
      errors.add(:duration, "must be greater than zero")
    end
  end

  def effective_duration
    d = duration
    if volunteer_task_type
      d *= volunteer_task_type.hours_multiplier
    end
    if community_service_type
      d *= community_service_type.hours_multiplier
    end
    return d
  end

  def type_of_task?(type)
    program.name == type
  end

  def add_contact_types
    # automatically make the person who did this a volunteer
    # the following is commented out because only
    # volunteers can be searched for... but non-volunteers
    # can become volunteers, can't they? See ticket #234
    required = [ContactType.find_by_name("volunteer")] # volunteer
    if type_of_task?('build')
      required << ContactType.find_by_name("build") # builder
    elsif type_of_task?('adoption')
      required << ContactType.find_by_name("adopter") # adopter
    end
    for type in required
      unless contact.contact_types.include?(type)
        contact.contact_types << type
      end
    end
  end
end
