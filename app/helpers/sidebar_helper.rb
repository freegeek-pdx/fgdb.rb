module SidebarHelper
  # TODO: add methods like this that control it for all 4 transactions + hours, reports, and contact dedup
  # TODO: get this from some table or something

  def should_show_library
    true
  end

  def should_show_fgss
    true
  end

  def should_show_schedule
    true
  end

  # TODO: kill this once rfs tells me to
  def should_show_edit_schedule
    false
  end

  def sidebar_stuff
    # base
    aliases = {:a => :action, :c => :controller}
    sidebar_hash = OH.n
    # hours
    if has_role?("VOLUNTEER_MANAGER")
      sidebar_hash.a("hours", OH.n("entry", :c => "volunteer_tasks"))
    elsif current_user and current_user.contact_id
      sidebar_hash.a("hours", OH.n("entry", :c => "volunteer_tasks", :contact_id => current_user.contact_id))
    end
    # transactions
    required_roles = {:donation => ["FRONT_DESK"], :sale => ["STORE"], :recycling => ["FRONT_DESK", "RECYCLINGS"], :disbursement => ['CONTACT_MANAGER', 'FRONT_DESK', 'STORE', 'VOLUNTEER_MANAGER']}
    trans_list = ['donation', 'sale', 'recycling', 'disbursement']
    trans_list.each do |i|
      x = required_roles[i.to_sym]
      if x.nil? || has_role?(*x)
        pl = i.pluralize
        trans = OH.n("entry", {:c => pl}, "search", {:c => pl, :a => 'search'})
        sidebar_hash.a(pl, trans)
      end
    end
    # reports
    reports = OH.n
    ["income", "gizmos", "volunteering"].each do |x|
      reports.a(x, :c => "reports", :a => x)
    end
    reports["over time"] = {:c => 'graphic_reports'}
    sidebar_hash.a("reports", reports)
    # contacts
    if has_role?('CONTACT_MANAGER', 'FRONT_DESK', 'STORE', 'VOLUNTEER_MANAGER')
      contacts = OH.n
      contacts.a("contacts", :c => "contacts") if has_role?('CONTACT_MANAGER', 'FRONT_DESK', 'STORE', 'VOLUNTEER_MANAGER')
      contacts.a("dedup", :c => 'contact_duplicates') if has_role?('CONTACT_MANAGER')
      contacts.a("duplicates list", :c => 'contact_duplicates', :a => "list_dups") if has_role?('CONTACT_MANAGER')
      sidebar_hash.a("contacts", contacts)
    end
    # staffsched
    staffsched = OH.n("staffsched", "/staffsched")
    staffsched.a("edit schedule", :c => "work_shifts") if should_show_edit_schedule and has_role?('SKEDJULNATOR')
    sidebar_hash.a("staff schedule", staffsched) if should_show_schedule
    # library
    lib = OH.n
    requires_librarian = ['overdue', 'labels']
    for i in ['lookup', 'overdue', 'cataloging', 'search', 'labels'] do
      if !requires_librarian.include?(i) or has_role?("LIBRARIAN")
        lib.add(i, :c => "library", :a => i)
      end
    end
    sidebar_hash.add("library", lib) if should_show_library
    # fgss
    fgss = OH.n("printme", :c => 'spec_sheets')
    fgss.a("fix contract", :c => 'spec_sheets', :a => "fix_contract") if Contract.find(:all).length > 1 && has_role?("ADMIN") # TODO: fix this
    sidebar_hash.add("fgss", fgss) if should_show_fgss
    # done
    return aliases, sidebar_hash
  end
end
