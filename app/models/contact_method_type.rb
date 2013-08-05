class ContactMethodType < ActiveRecord::Base
  acts_as_tree

  def self.sorted_order
    hardcoded = [ContactMethodType.find_by_name("phone"), ContactMethodType.find_by_name("cell_phone"), ContactMethodType.find_by_name("home_phone"), ContactMethodType.find_by_name("ip_phone"), ContactMethodType.find_by_name("work_phone"), ContactMethodType.find_by_name("email"), ContactMethodType.find_by_name("home_email"), ContactMethodType.find_by_name("work_email"), ContactMethodType.find_by_name("liason"), ContactMethodType.find_by_name("emergency_phone"), ContactMethodType.find_by_name("fax"), ContactMethodType.find_by_name("home_fax"), ContactMethodType.find_by_name("work_fax")]
    all = hardcoded.select{|x| !!x} + (ContactMethodType.all - hardcoded)
  end

  def self.sort_methods(methods)
    endlist = []
    self.sorted_order.each do |mt|
      endlist += methods.select{|x| x.contact_method_type_id == mt.id}
    end
    return endlist
  end

  # reversed for organizations
  def self.email_types_ordered
    last = ContactMethodType.find_by_name("email")
    a = last.children
    a = a.sort_by(&:description)
    a.insert(1, last)
    a
  end

  def to_s
    description
  end
end
