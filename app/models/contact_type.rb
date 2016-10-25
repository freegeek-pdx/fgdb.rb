class ContactType < ActiveRecord::Base
  validates_uniqueness_of :name, :message => "already exists"
#  has_and_belongs_to_many :contacts

  def self.newsletter
    find_by_name('newsletter')
  end

  def self.find_instantiable
    find(:all, :conditions => ["instantiable = ?", true], :order => "description")
  end

  def self.builder_relevent # this should be metadata probably
    ContactType.find_instantiable.select{|x| x.name.match(/_build/) or x.name == "advanced_testing" or x.name.match(/completed_/)}
  end

  def self.bulk_buyer
    ContactType.find_by_name("bulk_buyer")
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
