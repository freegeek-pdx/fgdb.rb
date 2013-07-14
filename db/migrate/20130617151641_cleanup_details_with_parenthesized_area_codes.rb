class CleanupDetailsWithParenthesizedAreaCodes < ActiveRecord::Migration
  def self.up
   # egrep '' details | egrep -v '^".{0,10}",'
    types = ContactMethodType.all.select{|x| x.name.match(/phone|fax/i)}.map(&:id)
    cmethods = ContactMethod.find(:all, :conditions => ['length(value) <= 10', types])
    cmethods.each_with_index do |c, i|
      puts "Checking record (#{i}/#{cmethods.length}, #{100*i/cmethods.length.to_f}%): ##{c.id}"
      orig = c.value
      origd = c.details
      ret = origd && origd.match(/(?:1-?)?[\(][0-9]+[\)]-?/)
      if ret
        c.details = origd.sub(ret.to_s, "")
        c.value = ret.to_s + orig
        puts "   #{orig} => (#{c.value}, #{c.details})"
        c.save!
      end
    end
    DB.exec("UPDATE contact_methods SET details = REPLACE(details, '1-', '') WHERE details IS NOT NULL AND details LIKE '%1-';")
  end

  def self.down
  end
end
