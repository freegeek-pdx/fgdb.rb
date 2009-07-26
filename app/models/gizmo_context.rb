class GizmoContext < ActiveRecord::Base
  has_and_belongs_to_many  :gizmo_types

  def to_s
    description
  end

  def abbrev
    name[0..2].capitalize
  end

  def GizmoContext.find_all_for_select
    find(:all).map {|context| [context.description, context.id]}
  end

  def GizmoContext.donation
    @@donation ||= find_by_name('donation')
  end

  def GizmoContext._gizmo_return
    g = find_by_name('gizmo_return')
    def g.gizmo_types
      (GizmoContext.disbursement.gizmo_types + GizmoContext.sale.gizmo_types).uniq
    end
    return g
  end

  def GizmoContext.gizmo_return
    @@gizmo_return ||= GizmoContext._gizmo_return
  end

  def GizmoContext.sale
    @@sale ||= find_by_name('sale')
  end

  def GizmoContext.disbursement
    @@disbursement ||= find_by_name('disbursement')
  end
  def GizmoContext.recycling
    @@recycling ||= find_by_name('recycling')
  end
end
