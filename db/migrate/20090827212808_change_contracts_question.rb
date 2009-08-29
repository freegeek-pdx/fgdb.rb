class ChangeContractsQuestion < ActiveRecord::Migration
  def self.up
    c = Contract.find_by_name('default')
    c.label = "No Sticker"
    c.save!
    if Default["is-pdx"] == "true"
    c = Contract.find_by_name('city')
    c.label = "FG-PDX"
    c.save!
    end
  end

  def self.down
    c = Contract.find_by_name('default')
    c.label = "keeper"
    c.save!
    if Default["is-pdx"] == "true"
    c = Contract.find_by_name('city')
    c.label = "fg-pdx"
    c.save!
    end
  end
end
