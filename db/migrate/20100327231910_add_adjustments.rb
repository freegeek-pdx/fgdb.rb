class AddAdjustments < ActiveRecord::Migration
  def self.up
    for i in %w[sales disbursements gizmo_returns donations recyclings]
      add_column i, "adjustment", :boolean, :null => false, :default => false
    end
    for i in %w[sales donations gizmo_returns]
      add_column i, "occurred_at", :datetime
      DB.exec("UPDATE #{i} SET occurred_at = created_at;")
      change_column(i, "occurred_at", :datetime, :null => false)
    end
  end

  def self.down
    for i in %w[sales disbursements gizmo_returns donations recyclings]
      remove_column i, "adjustment"
    end
    for i in %w[sales donations gizmo_returns]
      remove_column i, "occurred_at"
    end
  end
end
