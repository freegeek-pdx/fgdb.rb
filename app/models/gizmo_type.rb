class GizmoType < ActiveRecord::Base
  acts_as_tree
  has_many  :discount_schedules_gizmo_types,
  :dependent => :destroy
  has_many  :discount_schedules, :through => :discount_schedules_gizmo_types
  has_and_belongs_to_many    :gizmo_contexts

  validates_numericality_of(:required_fee_cents,
                            :suggested_fee_cents,
                            :allow_nil => true)
  belongs_to :gizmo_category

  define_amount_methods_on("required_fee")
  define_amount_methods_on("suggested_fee")

  def GizmoType.fee?(type)
    return type == service_fee || type == fee_discount
  end

  def GizmoType.service_fee
    @@service_fee ||= find_by_name('service_fee')
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

  def displayed_discounts
    discount_schedules_gizmo_types.map {|bridge| "%s: %0.2f" % [bridge.discount_schedule.name, bridge.multiplier]}.join(', ')
  end

  def relevant_attrs(context)
    relevant_typeattrs(context).map {|typeattr|
      typeattr.gizmo_attr
    }
  end

  def relevant_typeattrs(context)
    typeattrs = gizmo_typeattrs.select {|typeattr|
      (typeattr.gizmo_contexts.include? context) and
      (typeattr.is_required)
    }
    typeattrs += self.parent.relevant_typeattrs(context) if self.parent
    typeattrs
  end

  def possible_attrs
    possible_typeattrs.map {|typeattr|
      typeattr.gizmo_attr
    }
  end

  def possible_typeattrs
    if parent
      gizmo_typeattrs + parent.possible_typeattrs
    else
      gizmo_typeattrs
    end
  end

  def multiplier_to_apply(schedule)
    mult = schedule.multiplier_for(self)
    if ! mult
      if parent
        mult = parent.multiplier_to_apply(schedule)
      else
        mult = 1.0
      end
    end
    mult
  end
end
