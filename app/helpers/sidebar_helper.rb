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

  def should_show_edit_schedule
    true
  end

  # exceptions
  def controller_and_action_to_section
    h = OH.new
    h.default_class = OH
    h["gizmo_returns"]["system"] = "tech support"
    h["spec_sheets"]["system"] = "tech support"
    h
  end

  def controller_to_section
    {"recyclings" => "recyclings",
    "volunteer_tasks" => "hours",
    "sales" => "sales",
    "work_orders" => "tech support",
    "warranty_lengths" => "tech support",
    "donations" => "donations",
    "disbursements" => "disbursements",
    "reports" => "reports",
    "graphic_reports" => "reports",
    "work_shifts" => "staff schedule",
    "contacts" => "contacts",
    "contact_duplicates" => "contacts",
#    "library" => "library",
    "spec_sheets" => "build",
    "gizmo_returns" => "sales",
    "till_adjustments" => "bean counters",
    "worked_shifts" => "staff",
    "points_trades" => "hours",
    "volunteer_events" => "sked admin",
    "volunteer_default_events" => "sked admin",
    "default_assignments" => "sked admin",
    "volunteer_shifts" => "sked admin",
    "resources" => "sked admin",
    "skeds" => "sked admin",
    "rosters" => "sked admin",
    "volunteer_default_shifts" => "sked admin",
    "assignments" => "vol sked",
    "logs" => "admin",
    "system_pricings" => "sales",
    "pricing_types" => "sales",
    "pricing_components" => "sales",
    "pricing_values" => "sales" # Going away?
    }
  end

  def sidebar_stuff
    # base
    aliases = {:a => :action, :c => :controller}
    sidebar_hash = OH.n
    sidebar_hash.default_class = OH
    # hours
    sidebar_hash["hours"]["entry"] = {:c => "volunteer_tasks"}
    sidebar_hash["hours"]["points trade"] = {:c => 'points_trades'}
    # transactions
    for i in [:donation, :sale, :recycling, :disbursement, :gizmo_return] do
      pl = i.to_s.pluralize
      disp = pl.sub("gizmo_returns", "sales")
      prep = ([:sale, :gizmo_return].include?(i) ? pl.sub("gizmo_", "") + " " : "")
      sidebar_hash[disp][prep + "entry"] = {:c => pl}
      if [:donation].include?(i) # TODO: , :sale
        sidebar_hash[disp][prep + "invoices"] = {:c => pl, :a => "invoices"}
        sidebar_hash[disp]["tally sheet"] = {:c => pl, :a => "tally_sheet"}
      end
      sidebar_hash[disp][prep + "search"] = {:c => pl, :a => 'search'}
    end
    sidebar_hash["sales"]["store credits"] = {:c => "store_credits", :a => 'index'}
    sidebar_hash["sales"]["pricing"] = {:c => "system_pricings", :a => "index"}
    sidebar_hash["sales"]["pricing admin"] = {:c => "pricing_types", :a => "index"}
    # reports
    ["income", "gizmos", "volunteering", "top_donations", "donation_areas", "contributions", "volunteer_schedule"].each do |x|
      sidebar_hash["reports"][x.gsub(/_/, " ")] = {:c => "reports", :a => ((x == "contributions") ? "suggested_contributions" : (x == "donation_areas") ? "donation_zip_areas" : x.sub("ing", "s"))}
    end
    sidebar_hash["recyclings"]["shipments"] = {:c => "recycling_shipments"}
    sidebar_hash["tech support"]["system returns"] = {:c => "gizmo_returns", :a => "system"}
    sidebar_hash["tech support"]["system history"] = {:c => "spec_sheets", :action => "system"}
    sidebar_hash["tech support"]["work orders"] = {:c => "work_orders"}
    sidebar_hash["tech support"]["warranty config"] = {:c => "warranty_lengths"}
    sidebar_hash["reports"]["trends"] = {:c => 'graphic_reports'}
    sidebar_hash["reports"]["cashier contributions"] = {:c => 'reports', :action => "cashier_contributions"}
    # contacts
    sidebar_hash["contacts"]["contacts"] = {:c => "contacts"}
    sidebar_hash["contacts"]["dedup"] = {:c => 'contact_duplicates'}
    sidebar_hash["contacts"]["duplicates list"] = {:c => 'contact_duplicates', :a => "list_dups"}
    sidebar_hash["contacts"]["email list"] = {:c => 'contacts', :a => "email_list"}
    sidebar_hash["contacts"]["roles"] = {:c => 'contacts', :a => "roles"}
    # bean counters
    sidebar_hash["bean counters"]["till adjustments"] = {:c => "till_adjustments"}
    sidebar_hash["bean counters"]["inventory settings"] = {:c => "till_adjustments", :a => "inventory_settings"}
    # skedjuler
    sidebar_hash["sked admin"]["add intern"] = {:c => "volunteer_default_events", :a => "add_shift"}
    sidebar_hash["sked admin"]["repeat slots"] = {:c => "volunteer_default_shifts"}
    sidebar_hash["sked admin"]["actual slots"] = {:c => "volunteer_shifts"}
    sidebar_hash["sked admin"]["repeat volunteers"] = {:c => "default_assignments"}
    sidebar_hash["vol sked"]["schedule"] = {:c => "assignments"}
    sidebar_hash["vol sked"]["view only"] = {:c => "assignments", :a => "view"}
    sidebar_hash["vol sked"]["no shows"] = {:c => "assignments", :a => "noshows"}
    sidebar_hash["vol sked"]["search"] = {:c => "assignments", :a => "search"}
    # staffsched
    sidebar_hash["staff"]["schedule"] = {:c => "work_shifts", :a => "staffsched"} if should_show_schedule
    sidebar_hash["staff"]["holidays"] = {:c => "holidays", :a => "display"}
    sidebar_hash["staff"]["edit schedule"] = {:c => "work_shifts"} if should_show_edit_schedule
    sidebar_hash["staff"]["staff hours"] = {:c => "worked_shifts"}
    sidebar_hash["staff"]["individual report"] = {:c => "worked_shifts", :a => "individual"}
    sidebar_hash["staff"]["breaks report"] = {:c => "worked_shifts", :a => "breaks"}
    sidebar_hash["staff"]["jobs report"] = {:c => "reports", :a => "staff_hours"}
    sidebar_hash["staff"]["types report"] = {:c => "worked_shifts", :a => "type_totals"}
    sidebar_hash["staff"]["payroll report"] = {:c => "worked_shifts", :a => "payroll"}
    sidebar_hash["staff"]["weekly report"] = {:c => "worked_shifts", :a => "weekly_workers"}
    sidebar_hash["staff"]["hours summary"] = {:a => 'staff_hours_summary', :c => "reports"}
    sidebar_hash["staff"]["badges"] = {:a => 'badge', :c => "workers"}
    # library
#    requires_librarian = ['overdue', 'labels', 'cataloging', 'borrowers', 'inventory']
#    for i in ['lookup', 'overdue', 'inventory', 'cataloging', 'search', 'labels', 'borrowers'] do
#      if !requires_librarian.include?(i) or has_privileges("LIBRARIAN")
#        sidebar_hash["library"][i] = {:c => "library", :a => i}
#      end
#    end
    # fgss
    sidebar_hash["build"]["printme"] = {:c => 'spec_sheets'}
    sidebar_hash["build"]["fix contract"] = {:c => 'spec_sheets', :a => "fix_contract"} if contract_enabled
    sidebar_hash["build"]["proc db"] = {:c => 'spec_sheets', :a => 'lookup_proc'}
    sidebar_hash["data sec"]["disktest runs"] = {:c => "disktest_runs"}
    sidebar_hash["data sec"]["disktest batches"] = {:c => "disktest_batches"}
    # done
    sidebar_hash["admin"]["logs"] = {:c => "logs"}
    sidebar_hash["admin"]["deleted records"] = {:c => "logs", :a => "find_deleted"}
    sidebar_hash["feedback"] = "http://technocrats.freegeek.org/cgi-bin/technocrats.pl?_submitted_new_$_=1&mode=new_technocrats&infrastructure=fgdb.rb/SPECIFICALLY?"
    return aliases, sidebar_hash
  end
end
