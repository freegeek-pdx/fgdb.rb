class VolunteerTaskType < ActiveRecord::Base
  acts_as_tree

  def to_s
    description
  end

  def self.root_nodes
    find_all_by_parent_id(0)
  end

  named_scope :instantiables, { :conditions => {'instantiable' => true} }

  named_scope :effective_on, lambda { |date|
    { :conditions => ['(effective_on IS NULL OR effective_on <= ?) AND (ineffective_on IS NULL OR ineffective_on > ?)', date, date] }
  }

  def self.find_actual(*ids)
    ids.delete_if {|id| id == 0 }
    find(*ids)
  end

  def all_descendants
    all = children + children.map do |child|
      child.all_descendants
    end
    all.flatten
  end

  def all_instantiable_descendants
    kids = self.all_descendants.find(:all) do |child|
      child.instantiable
    end
    kids.unshift(self) if self.instantiable
    kids
  end

  def type_of_task?(type)
    (name == type) ||
      ( parent &&
        parent.type_of_task?(type) )
  end

  def display_name
    parents = ancestors
    parents.pop # get rid of the root node
    parents.pop # get rid of the assumed program type
    if parents.empty?
      description
    else
      parents.reverse!
      "%s (%s)" % [description, parents.map {|type| type.description}.join(":")]
    end
  end
end
