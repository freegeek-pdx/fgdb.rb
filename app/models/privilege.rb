class Privilege < ActiveRecord::Base
  validates_uniqueness_of :name
  has_and_belongs_to_many :roles

  def self.by_name(name)
    Privilege.find_by_name(name) || Privilege.new(:name => name, :restrict => false)
  end

  def children
    ret = []
    if self.name.match(/^role_(.+)$/)
      ret << Role.find_by_name($1.upcase).privileges
    end
    ret
  end

  def self.required_for_controller(controller_name)
    rules[controller_name] || global_rules
  end

  def self.ruleset
    [{:only => ["/contact_condition_everybody"], :privileges => ['manage_contacts']},
{:only => ['/admin_user_accounts'], :privileges => ['role_admin']},
{:only => ['/create_logins'], :privileges => ['can_create_logins']},
{:only => ['/modify_all_workers'], :privileges => ['log_all_workers_hours']},
{:only => ["/worker_condition"], :privileges => ['manage_workers', 'staff']},
{:only => ["/contact_condition"], :privileges => ['manage_contacts', 'has_contact']},
{:only => ["/view_contact_name"], :privileges => ['manage_contacts']},
{:only => ["/search_by_contact"], :privileges => ['manage_contacts', 'has_contact']},
{:only => ["/everybody"], :privileges => ['manage_volunteer_hours']},
     {:only => ["/admin_inventory_features"], :privileges => ['role_admin']},
     ["assignments", {:privileges => ['schedule_volunteers']}],
     ["assignments", {:only => ['view'], :privileges => ['schedule_volunteers', 'view_volunteer_schedule']}],
     ["assignments", {:only => ['noshows', 'noshows_report'], :privileges => ['admin_skedjul']}],
     ["builder_tasks", {:privileges => ['sign_off_spec_sheets']}],
     ["builder_tasks", {:only => ["/view_contact_name"], :privileges => ['manage_contacts']}],
     ["contact_duplicates", {:privileges => ['manage_contacts']}],
     ["contacts", {:privileges => ['manage_contacts'], :except => ['check_cashier_code', 'civicrm_sync']}],
     ["contacts", {:only => ['roles', '/admin_user_accounts'], :privileges => ['role_admin']}],
     ["contacts", {:only => ['email_list'], :privileges => ['staff']}],
     ["contacts", {:only => ['/create_logins'], :privileges => ['can_create_logins']}],
     ["customizations", {:privileges => ['skedjulnator']}],
     ["default_assignments", {:privileges => ['admin_skedjul']}],
     ["disktest_batches", {:privileges => ['data_security']}],
     ["gizmo_type_groups", {:privileges => ['manage_gizmo_type_groups']}],
     ["holidays", {:privileges => ['skedjulnator'], :except => ["is_holiday", "display", 'show_display']}],
     ["jobs", {:privileges => ['skedjulnator']}],
     ["logs", {:privileges => ['view_logs']}],
     ["meeting_minders", {:privileges => ['skedjulnator']}],
     ["meetings", {:privileges => ['skedjulnator']}],
     ["points_trades", {:privileges => ['manage_volunteer_hours']}],
     ["pricing_components", {:privileges => ['manage_pricing']}],
     ["pricing_types", {:privileges => ['manage_pricing']}],
     ["pricing_values", {:privileges => ['manage_pricing']}],
     ["recycling_shipments", {:privileges => ['staff']}],
     ["reports", {:only => ["top_contributors", "top_contributors_report"], :privileges => ['manage_contacts']}],
     ["reports", {:only => ["cashier_contributions", "cashier_contributions_report"], :privileges => ['staff']}],
     ["reports", {:only => ["/worker_condition"], :privileges => ['manage_workers', 'staff']}],
     ["reports", {:only => ["/contact_condition"], :privileges => ['manage_contacts', 'has_contact']}],
     ["reports", {:only => ["staff_hours_summary", "staff_hours_summary_report"], :privileges => ['staff_summary_report']}],
     ["reports", {:only => ["volunteer_schedule", "volunteer_schedule_report"], :privileges => ['admin_skedjul']}],
     ["reports", {:only => ["staff_hours", "staff_hours_report"], :privileges => ['staff']}],
     ["resources", {:privileges => ['admin_skedjul']}],
     ["resources_volunteer_default_events", {:privileges => ['admin_skedjul']}],
     ["resources_volunteer_events", {:privileges => ['admin_skedjul']}],
     ["rosters", {:privileges => ['admin_skedjul']}],
     ["rr_items", {:privileges => ['skedjulnator']}],
     ["rr_sets", {:privileges => ['skedjulnator']}],
     ["schedules", {:privileges => ['skedjulnator']}],
     ["shifts", {:privileges => ['skedjulnator']}],
     ["sidebar_links", {:privileges => ['role_admin'], :only => ["crash", "recent_crash"]}],
     ["skeds", {:privileges => ['admin_skedjul']}],
     ["spec_sheets", {:only => ["builder", "/view_contact_name"], :privileges => ['manage_contacts']}],
     ["spec_sheets", {:only => ["/search_by_contact"], :privileges => ['manage_contacts', 'has_contact']}],
     ["spec_sheets", {:only => ["show/sign_off"], :privileges => ['sign_off_spec_sheets']}],
     ["spec_sheets", {:only => ["workorder"], :privileges => ['role_tech_support']}],
     ["spec_sheets", {:only => ["fix_contract", "fix_contract_edit", "fix_contract_save"], :privileges => ['role_admin']}],
     ["store_credits", {:privileges => ["view_sales"]}],
     ["system_pricings", {:privileges => ['price_systems']}],
     ["tech_support_notes", {:privileges => ['staff'], :except => ['find_footnotes']}],
     ["tech_support_notes", {:privileges => ['techsupport_workorders'], :only => ['find_footnotes']}],
     ["till_adjustments", {:privileges => ['till_adjustments']}],
     ["till_adjustments", {:privileges => ['modify_inventory'], :only => ["inventory_settings", "save_inventory_settings"]}],
     ["unavailabilities", {:privileges => ['skedjulnator']}],
     ["vacations", {:privileges => ['skedjulnator']}],
     ["volunteer_default_events", {:privileges => ['admin_skedjul']}],
     ["volunteer_default_shifts", {:privileges => ['admin_skedjul']}],
     ["volunteer_events", {:privileges => ['admin_skedjul'], :except => ['display', 'toggle_walkins']}],
     ["volunteer_events", {:privileges => ['schedule_volunteers'], :only => ['display', 'toggle_walkins']}],
     ["volunteer_shifts", {:privileges => ['admin_skedjul']}],
     ["volunteer_tasks", {:privileges => ["contact_nil", 'manage_volunteer_hours']}],
     ["volunteer_tasks", {:only => ["/everybody"], :privileges => ['manage_volunteer_hours']}],
     ["warranty_lengths", {:privileges => ['role_admin']}],
     ["weekdays", {:privileges => ['skedjulnator']}],
     ["worked_shifts", {:only => [:weekly_worker, :payroll, :type_totals, :breaks, :breaks_report], :privileges => ['manage_workers']}],
     ["worked_shifts", {:except => [:weekly_worker, :payroll, :type_totals, :breaks, :breaks_report], :privileges => ['staff']}],
     ["worked_shifts", {:only => ['/modify_all_workers'], :privileges => ['log_all_workers_hours']}],
     ["workers", {:privileges => ['manage_workers']}],
     ["worker_types", {:privileges => ['skedjulnator']}],
     ["work_orders", {:privileges => ['techsupport_workorders']}],
     ["work_shifts", {:privileges => ['skedjulnator'], :except => ['staffsched', 'perpetual_meetings', 'staffsched_publish', 'perpetual_meetings_publish', 'staffsched_rolled_out', 'staffsched_month']}],
     ["sales", {:only => ["search", "component_update", "receipt"], :privileges => ["view_sales"]}],
     ["sales", {:only => ["edit", "destroy", "update"], :privileges => ["change_sales"]}],
     ["sales", {:only => ["invoices"], :privileges => ["pay_invoices"]}],
     ["sales", {:except => ["civicrm_sync", "receipt", "edit", "destroy", "update", "search", "component_update", "invoices"], :privileges => ["create_sales"]}],
     ["gizmo_returns", {:only => ["search", "component_update", "receipt"], :privileges => ["view_gizmo_returns"]}],
     ["gizmo_returns", {:only => ["edit", "destroy", "update"], :privileges => ["change_gizmo_returns"]}],
     ["gizmo_returns", {:only => ["invoices"], :privileges => ["pay_invoices"]}],
     ["gizmo_returns", {:except => ["civicrm_sync", "receipt", "edit", "destroy", "update", "search", "component_update", "invoices"], :privileges => ["create_gizmo_returns"]}],
     ["donations", {:only => ["search", "component_update", "receipt"], :privileges => ["view_donations"]}],
     ["donations", {:only => ["edit", "destroy", "update"], :privileges => ["change_donations"]}],
     ["donations", {:only => ["invoices"], :privileges => ["pay_invoices"]}],
     ["donations", {:except => ["civicrm_sync", "receipt", "edit", "destroy", "update", "search", "component_update", "invoices"], :privileges => ["create_donations"]}],
     ["disbursements", {:only => ["search", "component_update", "receipt"], :privileges => ["view_disbursements"]}],
     ["disbursements", {:only => ["edit", "destroy", "update"], :privileges => ["change_disbursements"]}],
     ["disbursements", {:only => ["invoices"], :privileges => ["pay_invoices"]}],
     ["disbursements", {:except => ["civicrm_sync", "receipt", "edit", "destroy", "update", "search", "component_update", "invoices"], :privileges => ["create_disbursements"]}],
     ["recyclings", {:only => ["search", "component_update", "receipt"], :privileges => ["view_recyclings"]}],
     ["recyclings", {:only => ["edit", "destroy", "update"], :privileges => ["change_recyclings"]}],
     ["recyclings", {:only => ["invoices"], :privileges => ["pay_invoices"]}],
     ["recyclings", {:except => ["civicrm_sync", "receipt", "edit", "destroy", "update", "search", "component_update", "invoices"], :privileges => ["create_recyclings"]}]]
  end

  def self.rules
    @@rules ||= _build_rules
  end

  def self.global_rules
    self.rules # build rules
    @@global_rules
  end
  
  def self._build_rules
    h = {}
    all = []
    self.ruleset.each do |x|
      if x.class == Hash
        all << x
      else
        h[x.first] ||= []
        h[x.first] << x.last
      end
    end
    @@global_rules = []
    all.each do |x|
      @@global_rules << x
      h.keys.each do |y|
        h[y] << x
      end
    end
    return h
  end
end
