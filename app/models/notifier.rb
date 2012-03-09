class Notifier < ActionMailer::Base
  def text_report(mail_default_name, subj, data)
    recipients Default[mail_default_name]
    from Default['my_email_address']
    headers 'return-path' => Default['return_path'] if Default['return_path']
    subject subj
    body :text => data
  end

  def newsletter_subscribe(email_address)
    recipients Default["newsletter_subscription_address"]
    from email_address
    headers 'return-path' => Default['return_path'] if Default['return_path']
    subject "Automatic Subscription during Donation Receipt"
    body
  end

  def donation_pdf(to_address, data, filename, type)
    recipients to_address
    from Default['noreply_address']
    headers 'return-path' => Default['return_path'] if Default['return_path']
    subject "Free Geek Donation #{type.capitalize}"
    attachment "application/pdf" do |x|
      x.filename = filename
      x.body = data
    end
    body :type => type
  end

  def holiday_announcement(subj, data)
    recipients Default['staff_mailing_list']
    from Default['my_email_address']
    headers 'return-path' => Default['return_path'] if Default['return_path']
    subject subj
    body :text => data
  end

  def volunteer_milestone_report( volunteers )
    recipients Default['volunteer_reports_to']
    from Default['my_email_address']
    headers 'return-path' => Default['return_path'] if Default['return_path']
    subject "Volunteer Milestone Report"
    body :volunteers => volunteers
  end

  def staff_hours_summary_report(myworkers)
    recipients Default['scheduler_reports_to']
    from Default['my_email_address']
    headers 'return-path' => Default['return_path'] if Default['return_path']
    subject "Staff Hours Summary"
    body :myworkers => myworkers
  end

  def staff_hours_poke(myworker)
    recipients myworker.name + " <" + myworker.email + ">"
    from Default['my_email_address']
    reply_to Default['scheduler_reports_to']
    headers 'return-path' => Default['return_path'] if Default['return_path']
    subject "Please log your hours"
    body :myworker => myworker
  end
end
