class UpdateRetailSaleTypeDescription < ActiveRecord::Migration
  def self.up
    st = SaleType.find_by_name('retail')
    st.description = "Retail"
    st.save
  end

  def self.down
  end
end
