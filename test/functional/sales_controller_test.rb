require File.dirname(__FILE__) + '/../test_helper'

class SalesControllerTest < ActionController::TestCase
  fixtures :discount_schedules, :payment_methods, :users, :roles, :roles_users, :contacts

  def cash_payment(amt)
    pmt = Payment.new
    pmt.amount = amt
    pmt.payment_method_id = 1
    return pmt
  end

  def create_a_new_sale
    s = Sale.new({:contact_type => 'named'})
    s.contact = Contact.find(:first)
    s.gizmo_events = [GizmoEvent.new(system_event)]
    s.gizmo_events[0].unit_price = 20
    s.payments = [cash_payment(20)]
    s.save
    return s
  end

  def test_basic_unauthorized_actions_redirect
    get :sales
    assert :redirect
  end

  def test_basic_authorized_actions_succeed
    login_as :quentin
    get :sales
    assert :success
  end

  def test_specific_unauthorized_actions_redirect
    sale = create_a_new_sale
    get :sales
    get :destroy, :id => sale.id, :scaffold_id => 'sales'
    assert Sale.find(sale.id)
    assert_response :redirect
  end

  def test_specific_authorized_actions_succeed
    login_as :quentin
    sale = create_a_new_sale
    get :sales
    get :destroy, :id => sale.id, :scaffold_id => 'sales'
    assert_raises(ActiveRecord::RecordNotFound) { Sale.find(sale.id) }
    assert_response :success
  end

  def test_filter_by_date
    login_as :quentin
    post :component_update, { "commit"=>"Refine", "conditions"=>{ "month"=>"2", "start_date"=>"", "end_date"=>"", "date"=>"2007-02-20", "date_type"=>"daily", "payment_method_id"=>"1", "year"=>"2008", "limit_type"=>"date range"}, "action"=>"component_update", "controller"=>"sales", "scaffold_id"=>"sale"}
    assert_response :success
    conditions = assigns(:conditions)
    assert_equal 2007, conditions.date.year
    assert_equal 2, conditions.date.month
  end

end
