require 'test_helper'

class WorkedShiftsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:worked_shifts)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_worked_shift
    assert_difference('WorkedShift.count') do
      post :create, :worked_shift => { }
    end

    assert_redirected_to worked_shift_path(assigns(:worked_shift))
  end

  def test_should_show_worked_shift
    get :show, :id => worked_shifts(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => worked_shifts(:one).id
    assert_response :success
  end

  def test_should_update_worked_shift
    put :update, :id => worked_shifts(:one).id, :worked_shift => { }
    assert_redirected_to worked_shift_path(assigns(:worked_shift))
  end

  def test_should_destroy_worked_shift
    assert_difference('WorkedShift.count', -1) do
      delete :destroy, :id => worked_shifts(:one).id
    end

    assert_redirected_to worked_shifts_path
  end
end
