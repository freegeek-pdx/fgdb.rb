class GizmoReturn < ActiveRecord::Base
  define_amount_methods_on("storecredit_difference")
  has_many :gizmo_events, :dependent => :destroy
  has_many :gizmo_types, :through => :gizmo_events
  include GizmoTransaction
  belongs_to :contact
  has_one :store_credit
  before_save :set_storecredit_difference_cents
  before_save :set_occurred_at_on_gizmo_events
  define_amount_methods_on("storecredit_difference")
  acts_as_userstamp
  before_save :set_occurred_at_on_transaction

  def storecredits
    [self.store_credit]
  end

  def self.default_sort_sql
    "gizmo_returns.created_at DESC"
  end

  def validate
    errors.add_on_empty("contact_id")
    if contact_id.to_i == 0 or !Contact.exists?(contact_id)
      errors.add("contact_id", "does not refer to any single, unique contact")
    end
    errors.add("gizmos", "should include something") if gizmo_events.empty?
  end

  def gizmo_context
    GizmoContext.gizmo_return
  end

  def editable
    !(store_credit && store_credit.spent?)
  end

  def store_credit_id
    self.store_credit.id
  end

  def set_storecredit_difference_cents
    self.storecredit_difference_cents = calculated_subtotal_cents
    if self.storecredit_difference_cents != 0
      self.store_credit ||= StoreCredit.new
      self.store_credit.amount_cents = self.storecredit_difference_cents
      self.store_credit.expire_date ||= (Date.today + 1.year)
    else
      self.store_credit.destroy if self.store_credit
      self.store_credit = nil
    end
  end

  def link_text
    self.created_at.strftime("%m/%d/%Y") + " (" + self.gizmos + ", $" + self.storecredit_difference + ")"
  end
end
