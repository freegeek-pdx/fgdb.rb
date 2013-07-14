class ContactVolunteerTaskTypeCount < ActiveRecord::Base
  belongs_to :contact
  belongs_to :volunteer_task_type

  def ContactVolunteerTaskTypeCount.has_volunteered?(contact_id, task_id)
    count = ContactVolunteerTaskTypeCount.find_by_contact_id_and_volunteer_task_type_id(contact_id, task_id)
    return false unless count
    return count.count != 0
  end
end
