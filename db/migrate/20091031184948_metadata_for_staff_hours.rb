class MetadataForStaffHours < ActiveRecord::Migration
  def self.up
    create_table :income_streams do |t|
      t.string :name
      t.string :description

      t.timestamps
    end

    create_table :wc_categories do |t|
      t.string :name
      t.string :description
      t.integer :rate_cents

      t.timestamps
    end

    create_table :programs do |t|
      t.string :name
      t.string :description

      t.timestamps
    end

    add_column :workers, :sunday, :float
    add_column :workers, :monday, :float
    add_column :workers, :tuesday, :float
    add_column :workers, :wednesday, :float
    add_column :workers, :thursday, :float
    add_column :workers, :friday, :float
    add_column :workers, :saturday, :float
    add_column :workers, :salaried, :boolean
    add_column :workers, :pto_rate, :float
    add_column :workers, :floor_hours, :float
    add_column :workers, :ceiling_hours, :float

    add_column :jobs, :income_stream_id, :integer
    add_column :jobs, :wc_category_id, :integer
    add_column :jobs, :program_id, :integer
  end

  def self.down
    drop_table :income_streams
    drop_table :wc_categories
    drop_table :programs

    remove_column :workers, :sunday
    remove_column :workers, :monday
    remove_column :workers, :tuesday
    remove_column :workers, :wednesday
    remove_column :workers, :thursday
    remove_column :workers, :friday
    remove_column :workers, :saturday
    remove_column :workers, :salaried
    remove_column :workers, :pto_rate
    remove_column :workers, :floor_hours
    remove_column :workers, :ceiling_hours

    remove_column :jobs, :income_stream_id
    remove_column :jobs, :wc_category_id
    remove_column :jobs, :program_id
  end
end
