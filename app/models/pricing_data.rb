class PricingData < ActiveRecord::Base
  def PricingData.load_from_csv(table_name, csv_data)
    table_name = table_name.downcase.gsub(' ', '_')
    rows = CSV.parse(csv_data)
    row_header = rows.shift
    row_header.shift # should be == table_name ?
    pd = []
    rows.each do |row|
      printme_value = row.shift
      row.each_with_index do |col, num|
        lookup_value = col
        lookup_type = row_header[num]
        pd << PricingData.new(:table_name => table_name, :printme_value => printme_value, :lookup_value => lookup_value, :lookup_type => lookup_type)
      end
    end
    PricingData.delete_table(table_name)
    pd.each{|x| x.save}
  end

  def PricingData.display_fields
    ["Brand", "Model", "Cores", "Clock Speed", "Release Date"]
  end

  def PricingData.delete_table(table_name)
    PricingData.destroy_all ['table_name LIKE ?', table_name]
  end

  def PricingData.find_match(table_name, printme_value)
    pd = nil
    PricingData.table_values(table_name).sort_by(&:length).reverse.each do |x|
      if PricingData.does_match?(x.to_s, printme_value.to_s)
        pd = x
      end
    end
    return pd
  end

  def PricingData.find_loose_match(table_name, printme_value)
    pd = nil
    PricingData.table_values(table_name).sort_by(&:length).reverse.each do |x|
      if PricingData.does_match?(printme_value.to_s, x.to_s)
        pd = x
      end
    end
    return pd
  end

  def self.does_match?(matcher, value)
    value ||= ""
    values = [value.downcase]
    for i in [/\s/, "-", ")", "("]
      values = values.map{|v| v.split(i)}.flatten
    end
    values = values.select{|x| x.length > 0}
    matcher.split(/[\s-]+/).select{|x| x.length > 0}.map(&:downcase).select{|x| !values.include?(x)}.length == 0
  end

  def PricingData.lookup_proc(proc_name)
    relevant_tables = PricingData.cpu_tables
    tables = []
    relevant_tables.each do |tbl|
      match = PricingData.find_match(tbl, proc_name)
      match = PricingData.find_loose_match(tbl, proc_name) if ! match
      if match
        h = {}
        tables << [tbl.titleize, match, h]
        PricingData.table_columns(tbl).each do |column|
          h[column] = PricingData.lookup(tbl, match, column)
        end
      end
    end
    return tables
  end

  def PricingData.cpu_tables
    PricingData.tables.select{|x| x.match(/cpu/i)}
  end

  def PricingData.lookup(table_name, printme_value, lookup_type)
    ret = nil
    ret = PricingData.find_by_table_name_and_printme_value_and_lookup_type(table_name, printme_value, lookup_type) if printme_value
    ret = ret.lookup_value if ret
    return ret
  end

  def PricingData.tables
    DB.exec("SELECT DISTINCT table_name FROM pricing_datas;").to_a.map{|x| x.values.first}
  end

  def PricingData.table_columns(tbl_name)
    DB.exec(["SELECT DISTINCT lookup_type FROM pricing_datas WHERE table_name LIKE ?;", tbl_name]).to_a.map{|x| x.values.first}
  end

  def PricingData.table_values(tbl_name)
    DB.exec(["SELECT DISTINCT printme_value FROM pricing_datas WHERE table_name LIKE ?;", tbl_name]).to_a.map{|x| x.values.first}
  end
end
