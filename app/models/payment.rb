class Payment < ActiveRecord::Base
  belongs_to :donation
  belongs_to :sale
  belongs_to :payment_method
  has_one :store_credit
  validates_presence_of :payment_method_id
  validates_associated :store_credit
  validates_presence_of :store_credit, :if => :is_storecredit?
  validates_each :amount_cents, :unless => Proc.new {|x| x.store_credit_id.nil?} do |record, attr, value|
    record.errors.add attr, 'is wonky. yell at Ryan please.' if record.store_credit.amount_cents != value
  end
  define_amount_methods_on("amount")

  def store_credit_id=(v)
    return if v.to_i == 0
    s = StoreCredit.find_by_id(v)
    return if s.nil?
    self.store_credit = s
  end

  def store_credit_id
    return nil if ! self.store_credit
    self.store_credit.id
  end

  def is_storecredit?
    payment_method.id == PaymentMethod.store_credit.id
  end

  def mostly_empty?
    # Allow negative payments (e.g. credits)
    #  http://svn.freegeek.org/projects/fgdb.rb/ticket/224
    ! ( valid? && amount_cents && (amount_cents != 0) )
  end

  def to_s
    "$%d.%02d %s" % [amount_cents/100, amount_cents%100, payment_method.description]
  end
end
