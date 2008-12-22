class RecyclingsController < TransactionController
  before_filter :authorized_only, :except => ["destroy", "edit", "update"]
  before_filter :management_only, :only => ["destroy", "edit", "update"]

  def default_condition
    "recycled_at"
  end

  protected

  def authorized_only
    requires_role('RECYCLINGS', 'FRONT_DESK')
  end

  def management_only
    requires_role(:BEAN_COUNTER)
  end
end
