#!/usr/bin/ruby

module CashiersHelper
  def cashierable
    params[:controller].classify.constantize.cashierable
  end

  def cashiers_field
    "<label for=\"cashier_code\">Cashier Code:</label><input name=\"cashier_code\" type=\"password\" id=\"cashier_code\" onKeyUp=\"update_cashier_code()\" autocomplete=\"off\"/>#{loading_indicator_tag("cashier_loading")}" if cashierable
  end

  def cashiers_javascript
    javascript_tag "update_cashier_code();" if cashierable
  end
end
