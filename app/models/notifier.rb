class Notifier < ActionMailer::Base
  def volunteer_milestone_report( volunteers )
    recipients Default['volunteer_reports_to']
    from Default['my_email_address']
    subject "Volunteer Milestone Report"
    body :volunteers => volunteers
  end

  def staff_hours_summary_report(myworkers)
    recipients Default['scheduler_reports_to']
    from Default['my_email_address']
    subject "Staff Hours Summary"
    body :myworkers => myworkers
  end

  def staff_hours_poke(myworker)
    recipients myworker.name + " <" + myworker.email + ">"
    from Default['my_email_address']
    reply_to Default['scheduler_reports_to']
    subject "Please log your hours"
    body :myworker => myworker
  end
end
