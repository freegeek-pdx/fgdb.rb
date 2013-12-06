class CleanupExistingNonprintablePrintmeValues < ActiveRecord::Migration
  def self.up
    allbad = SpecSheetValue.all.select{|x| x.value.match(/[^\p{Print}]+/)}
    puts allbad.count.to_s + " records with nonprintable characters found before migration."
    allbad.each do |x|
      x.remove_nonprintables_from_value
      x.save!
    end
    puts SpecSheetValue.all.select{|x| x.value.match(/[^\p{Print}]+/)}.count.to_s + " records with nonprintable characters found after migration."
  end

  def self.down
  end
end
