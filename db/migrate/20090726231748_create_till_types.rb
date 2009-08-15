class CreateTillTypes < ActiveRecord::Migration
  def self.up
    create_table :till_types do |t|
      t.string :name

      t.timestamps
    end
    DB.execute('ALTER TABLE "till_types" ADD COLUMN "description" character varying(255);') # rails is being dumb.
    {:fd => 'Front Desk', :ts => 'Thrift Store', :xx => 'Misc.'}.each{|x,y|
      TillType.new({:name => x.to_s.upcase, :description => y}).save
    }
    add_index "till_types", ["name"], :unique => true
  end

  def self.down
    drop_table :till_types
  end
end
