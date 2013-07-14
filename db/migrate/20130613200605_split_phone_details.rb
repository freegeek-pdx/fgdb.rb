class SplitPhoneDetails < ActiveRecord::Migration
  def self.up
    add_column :contact_methods, :details, :string
    DB.exec("ALTER TABLE contact_methods DROP CONSTRAINT contact_methods_not_empty;")
    DB.exec("ALTER TABLE contact_methods ADD CONSTRAINT contact_methods_not_empty CHECK (char_length(value::text) > 0 OR char_length(details::text) > 0);")

    types = ContactMethodType.all.select{|x| x.name.match(/phone|fax/i)}.map(&:id)
    cmethods = ContactMethod.find(:all, :conditions => ['contact_method_type_id IN (?) AND length(value) > 32', types])
    cmethods.each_with_index do |c, i|
      puts "Cleaning record (#{i}/#{cmethods.length}, #{100*i/cmethods.length.to_f}%): ##{c.id}"
      orig = c.value
      ret = c.value.match(/[0-9]{2,}[ .-]*[0-9]{2,}[ .-]*[0-9]{2,}/)
      if ret
        c.details = c.value.sub(ret.to_s, "")
        c.value = ret.to_s
      else
        c.details = c.value
        c.value = ""
      end
      c.save!
      puts "   #{orig} => (#{c.value}, #{c.details})"
    end
  end

  def self.down
  end
end
