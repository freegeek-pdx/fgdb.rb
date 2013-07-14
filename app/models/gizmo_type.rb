class GizmoType < ActiveRecord::Base
  has_and_belongs_to_many    :gizmo_contexts
  belongs_to :return_policy

  validates_numericality_of(:required_fee_cents,
                            :suggested_fee_cents,
                            :allow_nil => true)
  belongs_to :gizmo_category

  define_amount_methods_on("required_fee")
  define_amount_methods_on("suggested_fee")

  named_scope :effective_on, lambda { |date|
    { :conditions => ['(effective_on IS NULL OR effective_on <= ?) AND (ineffective_on IS NULL OR ineffective_on > ?)', date, date] }
  }

  named_scope :for_systems, :conditions => ["needs_id = 't'"]

  def downcase_desc
    description.to_s.downcase
  end

  def GizmoType.fee?(type)
    return type.name.match(/^service_fee/) || type == fee_discount
  end

  def GizmoType.fee_discount
    @@fee_discount ||= find_by_name('fee_discount')
  end

  def fee_cents
    if (required_fee_cents && required_fee_cents > 0)
      return required_fee_cents
    elsif (suggested_fee_cents && suggested_fee_cents > 0)
      return suggested_fee_cents
    else
      return -1
    end
  end

  def to_s
    description
  end

  def parent(date)
    return if self.parent_name.nil?
    p = GizmoType.find_all_by_name(parent_name).select{|x| x.effective_on?(date)}.sort.last
    raise ActiveRecord::RecordNotFound if p.nil? and self.effective_on?(date)
    return p
  end

  def effective_on?(date)
    (effective_on.nil? || effective_on <= date) && (ineffective_on.nil? || ineffective_on > date)
  end

  def my_return_policy_id
    pol = self.return_policy_id
    if ! pol
      if p = parent(Date.today) # FIXME
        pol = p.my_return_policy_id
      end
    end
    pol
  end

  def multiplier_to_apply(schedule, date)
    mult = schedule.multiplier_for(self)
    if ! mult
      if parent(date)
        mult = parent(date).multiplier_to_apply(schedule, date)
      else
        mult = 1.0
      end
    end
    mult
  end
end
