class GizmoReturnsController < TransactionController
  before_filter :authorized_only, :except => ["destroy", "edit", "update"]
  before_filter :management_only, :only => ["destroy", "edit", "update"]

  def default_condition
    "created_at"
  end

  protected

  def authorized_only
    requires_role('STORE', 'TECH_SUPPORT')
  end

  def management_only
    requires_role('STORE_ADMIN', 'BEAN_COUNTER')
  end
end
