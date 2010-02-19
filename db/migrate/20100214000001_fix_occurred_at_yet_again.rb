class FixOccurredAtYetAgain < ActiveRecord::Migration
  def self.up
#    $stderr.puts '-- clearing occurred_at '
#    GizmoEvent.connection.execute("UPDATE gizmo_events SET occurred_at = NULL")
    $stderr.puts '-- SET occurred_at = recyclings.recycled_at'
    GizmoEvent.connection.execute("UPDATE gizmo_events
      SET occurred_at = (
        SELECT recycled_at FROM recyclings
        WHERE recyclings.id = gizmo_events.recycling_id
      )
      WHERE recycling_id IS NOT NULL AND occurred_at IS NULL")
    $stderr.puts '-- SET occurred_at = disbursements.disbursed_at'
    GizmoEvent.connection.execute("UPDATE gizmo_events
      SET occurred_at = (
        SELECT disbursed_at FROM disbursements
        WHERE disbursements.id = gizmo_events.disbursement_id
      )
      WHERE disbursement_id IS NOT NULL AND occurred_at IS NULL")
    $stderr.puts '-- SET occurred_at = donations.created_at'
    GizmoEvent.connection.execute("UPDATE gizmo_events
      SET occurred_at = (SELECT created_at FROM donations WHERE donations.id = donation_id)
      WHERE occurred_at IS NULL AND donation_id IS NOT NULL")
    $stderr.puts '-- SET occurred_at = sales.created_at'
    GizmoEvent.connection.execute("UPDATE gizmo_events
      SET occurred_at = (SELECT created_at FROM sales WHERE sales.id = sale_id)
      WHERE occurred_at IS NULL AND sale_id IS NOT NULL")
    $stderr.puts '-- SET occurred_at = gizmo_returns.created_at'
    GizmoEvent.connection.execute("UPDATE gizmo_events
      SET occurred_at = (SELECT created_at FROM gizmo_returns WHERE gizmo_returns.id = gizmo_return_id)
      WHERE occurred_at IS NULL AND gizmo_return_id IS NOT NULL")
#    $stderr.puts '-- SET occurred_at = created_at'
#    GizmoEvent.connection.execute("UPDATE gizmo_events
#      SET occurred_at = created_at
#      WHERE occurred_at IS NULL")
  end

  def self.down
  end
end
