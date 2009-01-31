class ContactType < ActiveRecord::Base
  validates_uniqueness_of :name, :message => "already exists"

  def self.find_instantiable
    find(:all, :conditions => ["instantiable = ?", true], :order => "description")
  end

  def to_s
    description
  end

  def long_for_who
    case for_who
    when 'per'
      'person'
    when 'org'
      'organization'
    else
      for_who
    end
  end

end
