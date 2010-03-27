class ConditionsBase
  DATES = []
  CONDS = []

  def apply_conditions(options)
    options.each do |name,val|
      val = val.to_i if( val.to_i.to_s == val )
      self.send(name+"=", val)
    end
    return options
  end

  def initialize
    for i in self.class::DATES
      eval("@#{i}_date = Date.today")
      eval("@#{i}_date_type = 'daily'")
      eval("@#{i}_month = Date.today")
      eval("@#{i}_year = Date.today")
    end

    @payment_method_id = PaymentMethod.cash.id
  end

  def conditions(klass)
    conds = self.class::CONDS.inject([""]) {|condition_array,this_condition|
      if instance_variable_get("@#{this_condition}_enabled") == "true"
        join_conditions(condition_array,
                        self.send("#{this_condition}_conditions",
                                  klass))
      else
        condition_array
      end
    }
    if conds[0].empty?
      conds[0]="#{klass.table_name}.id = -1"
    end
    return conds
  end
end
