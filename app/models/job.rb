class Job < ActiveRecord::Base
  has_many :standard_shifts
  has_many :work_shifts
  has_and_belongs_to_many :workers
  belongs_to :coverage_type
  belongs_to :program
  belongs_to :wc_category
  belongs_to :income_stream
  named_scope :workable, :conditions => {:virtual => false}

  def description
    read_attribute(:name)
  end

  def full_description
    read_attribute(:description)
  end

  def full_description=(a)
    self.description = a
  end
end

