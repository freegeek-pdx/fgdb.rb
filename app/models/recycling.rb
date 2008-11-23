class Recycling < ActiveRecord::Base
  include GizmoTransaction
  has_many :gizmo_events, :dependent => :destroy

  def validate
    errors.add_on_empty("gizmo_events")
    errors.add_on_empty("recycled_at", "when?")
  end

  before_save :set_occurred_at_on_gizmo_events

  class << self
    def default_sort_sql
      "recycled_at DESC"
    end
  end

  #######
  private
  #######

  def set_occurred_at_on_gizmo_events
    self.gizmo_events.each {|event| event.occurred_at = self.recycled_at; event.save!}
  end
end
