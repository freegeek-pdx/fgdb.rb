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
    sidebar_hash.default_class = OH
    # hours
    if has_role?("VOLUNTEER_MANAGER")
      sidebar_hash["hours"]["entry"] = {:c => "volunteer_tasks"}
    elsif current_user and current_user.contact_id
      sidebar_hash["hours"]["entry"] = {:c => "volunteer_tasks", :contact_id => current_user.contact_id}
    end
    # transactions
    {:donation => ["FRONT_DESK"], :sale => ["STORE"], :recycling => ["FRONT_DESK", "RECYCLINGS"], :disbursement => ['CONTACT_MANAGER', 'FRONT_DESK', 'STORE', 'VOLUNTEER_MANAGER']}.each do |i,x|
      if x.nil? || has_role?(*x)
        pl = i.to_s.pluralize
        sidebar_hash[pl]["entry"] = {:c => pl}
        sidebar_hash[pl]["search"] = {:c => pl, :a => 'search'}
      end
    end
    # reports
    ["income", "gizmos", "volunteering"].each do |x|
      sidebar_hash["reports"][x] = {:c => "reports", :a => x}
    end
    sidebar_hash["reports"]["over time"] = {:c => 'graphic_reports'}
    # contacts
    sidebar_hash["contacts"]["contacts"] = {:c => "contacts"} if has_role?('CONTACT_MANAGER', 'FRONT_DESK', 'STORE', 'VOLUNTEER_MANAGER')
    sidebar_hash["contacts"]["dedup"] = {:c => 'contact_duplicates'} if has_role?('CONTACT_MANAGER')
    sidebar_hash["contacts"]["duplicates list"] = {:c => 'contact_duplicates', :a => "list_dups"} if has_role?('CONTACT_MANAGER')
    # staffsched
    sidebar_hash["staff schedule"]["staffsched"] = "/staffsched" if should_show_schedule
    sidebar_hash["staff schedule"]["edit schedule"] = {:c => "work_shifts"} if should_show_edit_schedule and has_role?('SKEDJULNATOR')
    # library
    requires_librarian = ['overdue', 'labels']
    for i in ['lookup', 'overdue', 'cataloging', 'search', 'labels'] do
      if !requires_librarian.include?(i) or has_role?("LIBRARIAN")
        sidebar_hash["library"][i] = {:c => "library", :a => i}
      end
    end
    # fgss
    sidebar_hash["fgss"]["printme"] = {:c => 'spec_sheets'}
    sidebar_hash["fgss"]["fix contract"] = {:c => 'spec_sheets', :a => "fix_contract"} if Contract.find(:all).length > 1 && has_role?("ADMIN") # TODO: fix this
    # done
    return aliases, sidebar_hash
  end
end
