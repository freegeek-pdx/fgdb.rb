require File.dirname(__FILE__) + '/../test_helper'

class ConditionsTest < Test::Unit::TestCase
  fixtures :payment_methods

  def test_joining_conditions
    cond_a = ["id = ?", 1]
    cond_b = ["name = ?", 'meow']
    cond_c = nil
    assert_nothing_raised {cond_c = Conditions.new.join_conditions(cond_a, cond_b)}
    assert(/ AND /, cond_c[0])
    assert_equal 3, cond_c.length
  end

  def test_generating_month_conditions
    c = Conditions.new
    c.apply_conditions({
                         "month"=>"4", "start_date"=>"", "end_date"=>"",
                         "date"=>"2008-04-17", "date_type"=>"daily",
                         "date_range_enabled"=>"true", "year"=>"2008"
                       })
    assert_nothing_raised {c.conditions(GizmoEvent)}
    assert(/occurred_at/.match(c.conditions(GizmoEvent)[0]))
  end
end
