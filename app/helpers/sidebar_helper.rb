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
      "admin" => "admin",
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
    "store_pricings" => "sales",
    "pricing_types" => "sales",
    "pricing_components" => "sales",
      "disktest_batches" => "data sec",
      "disktest_runs" => "data sec",
    "pricing_values" => "sales" # Going away?
    }
  end

  def sidebar_stuff
    # base
#    sidebar_hash = Hash.new {|h, k| h[k] = {}}
    sidebar_hash = OH.new
    sidebar_hash.default_class = OH
    # hours
    sidebar_hash["hours"]["entry"] = {:controller => "volunteer_tasks"}
    sidebar_hash["hours"]["points trade"] = {:controller => 'points_trades'}
    # transactions
    for i in [:donation, :sale, :recycling, :disbursement, :gizmo_return] do
      pl = i.to_s.pluralize
      disp = pl.sub("gizmo_returns", "sales")
      prep = ([:sale, :gizmo_return].include?(i) ? pl.sub("gizmo_", "") + " " : "")
      sidebar_hash[disp][prep + "entry"] = {:controller => pl}
      if [:donation].include?(i) # TODO: , :sale
        sidebar_hash[disp][prep + "invoices"] = {:controller => pl, :action => "invoices"}
        sidebar_hash[disp]["tally sheet"] = {:controller => pl, :action => "tally_sheet"}
      end
      sidebar_hash[disp][prep + "search"] = {:controller => pl, :action => 'search'}
    end
    sidebar_hash["sales"]["store credits"] = {:controller => "store_credits", :action => 'index'}
    sidebar_hash["sales"]["pricing"] = {:controller => "store_pricings", :action => "index"}
    # reports
    ["income", "gizmos", "volunteering", "top_donations", "donation_areas", "contributions", "volunteer_schedule"].each do |x|
      sidebar_hash["reports"][x.gsub(/_/, " ")] = {:controller => "reports", :action => ((x == "contributions") ? "suggested_contributions" : (x == "donation_areas") ? "donation_zip_areas" : x.sub("ing", "s"))}
    end
    sidebar_hash["recyclings"]["shipments"] = {:controller => "recycling_shipments"}
    sidebar_hash["tech support"]["system returns"] = {:controller => "gizmo_returns", :action => "system"}
    sidebar_hash["tech support"]["system history"] = {:controller => "spec_sheets", :action => "system"}
    sidebar_hash["tech support"]["work orders"] = {:controller => "work_orders"}
    sidebar_hash["tech support"]["warranty config"] = {:controller => "warranty_lengths"}
    sidebar_hash["reports"]["trends"] = {:controller => 'graphic_reports'}
    sidebar_hash["reports"]["cashier contributions"] = {:controller => 'reports', :action => "cashier_contributions"}
    sidebar_hash["reports"]["monthly reports"] = {:controller => 'reports', :action => "monthly_reports"}
    # contacts
    sidebar_hash["contacts"]["contacts"] = {:controller => "contacts"}
    sidebar_hash["contacts"]["dedup"] = {:controller => 'contact_duplicates'}
    sidebar_hash["contacts"]["duplicates list"] = {:controller => 'contact_duplicates', :action => "list_dups"}
    sidebar_hash["contacts"]["email list"] = {:controller => 'contacts', :action => "email_list"}
    sidebar_hash["contacts"]["roles"] = {:controller => 'contacts', :action => "roles"}
    # bean counters
    sidebar_hash["bean counters"]["till adjustments"] = {:controller => "till_adjustments"}
    sidebar_hash["bean counters"]["inventory settings"] = {:controller => "till_adjustments", :action => "inventory_settings"}
    # skedjuler
    sidebar_hash["sked admin"]["add intern"] = {:controller => "volunteer_default_events", :action => "add_shift"}
    sidebar_hash["sked admin"]["repeat slots"] = {:controller => "volunteer_default_shifts"}
    sidebar_hash["sked admin"]["actual slots"] = {:controller => "volunteer_shifts"}
    sidebar_hash["sked admin"]["repeat volunteers"] = {:controller => "default_assignments"}
    sidebar_hash["vol sked"]["TURBO-pilot"] = {:controller => "assignments", :action => "turbo"}
    sidebar_hash["vol sked"]["schedule"] = {:controller => "assignments"}
    sidebar_hash["vol sked"]["view only"] = {:controller => "assignments", :action => "view"}
    sidebar_hash["vol sked"]["no shows"] = {:controller => "assignments", :action => "noshows"}
    sidebar_hash["vol sked"]["search"] = {:controller => "assignments", :action => "search"}
    # staffsched
    sidebar_hash["staff"]["schedule"] = {:controller => "work_shifts", :action => "staffsched"} if should_show_schedule
    sidebar_hash["staff"]["holidays"] = {:controller => "holidays", :action => "display"}
    sidebar_hash["staff"]["edit schedule"] = {:controller => "work_shifts"} if should_show_edit_schedule
#    sidebar_hash["staff"]["staff hours"] = {:controller => "worked_shifts"}
#    sidebar_hash["staff"]["individual report"] = {:controller => "worked_shifts", :action => "individual"}
#    sidebar_hash["staff"]["breaks report"] = {:controller => "worked_shifts", :action => "breaks"}
#    sidebar_hash["staff"]["jobs report"] = {:controller => "reports", :action => "staff_hours"}
#    sidebar_hash["staff"]["types report"] = {:controller => "worked_shifts", :action => "type_totals"}
#    sidebar_hash["staff"]["payroll report"] = {:controller => "worked_shifts", :action => "payroll"}
#    sidebar_hash["staff"]["weekly report"] = {:controller => "worked_shifts", :action => "weekly_workers"}
#    sidebar_hash["staff"]["hours summary"] = {:action => 'staff_hours_summary', :controller => "reports"}
    sidebar_hash["staff"]["badges"] = {:action => 'badge', :controller => "workers"}
    # library
#    requires_librarian = ['overdue', 'labels', 'cataloging', 'borrowers', 'inventory']
#    for i in ['lookup', 'overdue', 'inventory', 'cataloging', 'search', 'labels', 'borrowers'] do
#      if !requires_librarian.include?(i) or has_privileges("LIBRARIAN")
#        sidebar_hash["library"][i] = {:controller => "library", :action => i}
#      end
#    end
    # fgss
    sidebar_hash["build"]["printme"] = {:controller => 'spec_sheets'}
    sidebar_hash["build"]["fix contract"] = {:controller => 'spec_sheets', :action => "fix_contract"} if contract_enabled
    sidebar_hash["build"]["proc db"] = {:controller => 'spec_sheets', :action => 'lookup_proc'}
    sidebar_hash["data sec"]["disktest runs"] = {:controller => "disktest_runs"}
    sidebar_hash["data sec"]["disktest batches"] = {:controller => "disktest_batches"}
    sidebar_hash["data sec"]["record destroy"] = {:controller => "disktest_batches", :action => "mark_destroyed"}
    # done
    sidebar_hash["admin"]["config"] = {:controller => "admin", :model => nil}
    sidebar_hash["admin"]["logs"] = {:controller => "logs"}
    sidebar_hash["admin"]["deleted records"] = {:controller => "logs", :action => "find_deleted"}
    sidebar_hash["feedback"] = "http://technocrats.freegeek.org/cgi-bin/technocrats.pl?_submitted_new_$_=1&mode=new_technocrats&infrastructure=fgdb.rb/SPECIFICALLY?"
    return sidebar_hash
  end
end
