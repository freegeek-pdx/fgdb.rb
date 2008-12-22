class AddIsPdxFlag < ActiveRecord::Migration
  def self.up
    puts "Do you want this database to be treated like FreeGeek PDX (messing with your metadata)? (kc8pxy, say no, everybody else, say yes :D) "
    thing = $stdin.gets.chomp
    Default.new(:name => "is-pdx", :value => (thing == "yes").to_s).save!
  end

  def self.down
  end
end
