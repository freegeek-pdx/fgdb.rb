require 'test_helper'

class PointsTradesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:points_trades)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_points_trade
    assert_difference('PointsTrade.count') do
      post :create, :points_trade => { }
    end

    assert_redirected_to points_trade_path(assigns(:points_trade))
  end

  def test_should_show_points_trade
    get :show, :id => points_trades(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => points_trades(:one).id
    assert_response :success
  end

  def test_should_update_points_trade
    put :update, :id => points_trades(:one).id, :points_trade => { }
    assert_redirected_to points_trade_path(assigns(:points_trade))
  end

  def test_should_destroy_points_trade
    assert_difference('PointsTrade.count', -1) do
      delete :destroy, :id => points_trades(:one).id
    end

    assert_redirected_to points_trades_path
  end
end
