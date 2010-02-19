class MakeALotOfPayPeriods < ActiveRecord::Migration
  def self.up
    last = PayPeriod.find(:last)
    100.times do
      start_date = last.end_date + 1
      end_date = start_date + 13
      last = PayPeriod.new(:start_date => start_date, :end_date => end_date)
      last.save!
    end
  end

  def self.down
  end
end
