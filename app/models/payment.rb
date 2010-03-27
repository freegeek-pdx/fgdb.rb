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
  validate :sc_ok

  def my_transaction
    self.sale || self.donation
  end

  def type_description
    d = self.payment_method.name
    if d == "invoice"
      d = (self.my_transaction.invoice_resolved_at.nil? ? "unresolved" : "resolved") + "_" + d
    end
    return d
  end

  def editable
    return true
  end

  def store_credit_id=(v)
    return if v.to_i == 0
    s = StoreCredit.find_by_id(v)
    return if s.nil?
    s.cache_shit # cache it for sc_ok
    self.store_credit = s
  end

  def sc_ok
    return if ! is_storecredit?
    errors.add("payment", "store credit was already spent") if self.store_credit.spent? && (self.sale.nil? || self.store_credit.spent_on.sale.id != self.sale.id)
  end

  def store_credit_id
    return nil if ! self.store_credit
    self.store_credit.id
  end

  def is_storecredit?
    payment_method.id == PaymentMethod.store_credit.id
  end

  def mostly_empty?
    amount_cents == 0
  end

  def to_s
    "$%d.%02d %s" % [amount_cents/100, amount_cents%100, self.type_description.sub(/_/, " ")]
  end
end
