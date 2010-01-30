class WorkersWorkerType < ActiveRecord::Base
  named_scope :effective_on, lambda { |date|
    { :conditions => ['(effective_on IS NULL OR effective_on <= ?) AND (ineffective_on IS NULL OR ineffective_on > ?)', date, date] }
  }
  belongs_to :worker
  belongs_to :worker_type
#  validates_existence_of :worker
  validates_existence_of :worker_type
  validate :siblings_dont_overlap

  def smart_effective_on
    effective_on || Date.parse("1901-12-22")
  end

  def smart_ineffective_on
    ineffective_on || Date.parse("2100-12-31")
  end

  def siblings_dont_overlap
    arr = (worker.workers_worker_types.delete_if{|x| x.id == self.id} + [self]).sort_by(&:smart_effective_on)
    arr.each_with_siblings{|a,b,c| errors.add("effective_on", "worker_types effective dates overlap")  if (a && (a.ineffective_on.nil? or a.smart_ineffective_on > b.smart_effective_on)) || (c && (c.effective_on.nil? or c.smart_effective_on < b.smart_ineffective_on)); break}
    arr.each_with_siblings{|a,b,c| errors.add("effective_on", "worker_types effective dates leave holes")  if (a && (a.ineffective_on != b.effective_on)) || (c && (c.effective_on != b.ineffective_on)); break}
  end
end

