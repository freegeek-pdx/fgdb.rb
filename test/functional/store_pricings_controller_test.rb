require 'test_helper'

class StorePricingsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:store_pricings)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_store_pricing
    assert_difference('StorePricing.count') do
      post :create, :store_pricing => { }
    end

    assert_redirected_to store_pricing_path(assigns(:store_pricing))
  end

  def test_should_show_store_pricing
    get :show, :id => store_pricings(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => store_pricings(:one).id
    assert_response :success
  end

  def test_should_update_store_pricing
    put :update, :id => store_pricings(:one).id, :store_pricing => { }
    assert_redirected_to store_pricing_path(assigns(:store_pricing))
  end

  def test_should_destroy_store_pricing
    assert_difference('StorePricing.count', -1) do
      delete :destroy, :id => store_pricings(:one).id
    end

    assert_redirected_to store_pricings_path
  end
end
