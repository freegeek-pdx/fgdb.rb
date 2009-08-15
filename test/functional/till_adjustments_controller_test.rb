require 'test_helper'

class TillAdjustmentsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:till_adjustments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_till_adjustment
    assert_difference('TillAdjustment.count') do
      post :create, :till_adjustment => { }
    end

    assert_redirected_to till_adjustment_path(assigns(:till_adjustment))
  end

  def test_should_show_till_adjustment
    get :show, :id => till_adjustments(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => till_adjustments(:one).id
    assert_response :success
  end

  def test_should_update_till_adjustment
    put :update, :id => till_adjustments(:one).id, :till_adjustment => { }
    assert_redirected_to till_adjustment_path(assigns(:till_adjustment))
  end

  def test_should_destroy_till_adjustment
    assert_difference('TillAdjustment.count', -1) do
      delete :destroy, :id => till_adjustments(:one).id
    end

    assert_redirected_to till_adjustments_path
  end
end
