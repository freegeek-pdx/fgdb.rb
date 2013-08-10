class PricingTypesController < ApplicationController
  layout :with_sidebar

  protected
  public

  def index
    @pricing_types = PricingType.active
  end

  def new
    @pricing_type = PricingType.new
  end

  def edit
    @pricing_type = PricingType.find(params[:id])
  end

  def create
    @pricing_type = PricingType.new(params[:pricing_type])

    if @pricing_type.save
      flash[:notice] = 'PricingType was successfully created.'
      redirect_to({:action => "edit", :id => @pricing_type.id})
    else
      render :action => "new"
    end
  end

  def update
    orig_pricing_type = PricingType.find(params[:id])
    @pricing_type = orig_pricing_type.clone
    pe = []
    orig_pricing_type.pricing_expressions.each do |e|
      mult = params[:expr_mult][e.id.to_s]
      new = e.clone
      e.pricing_type = @pricing_type
      e.multiplier = mult
      pe << e
    end
    @pricing_type.pricing_expressions = pe

    if @pricing_type.update_attributes(params[:pricing_type]) && @pricing_type.save
      orig_pricing_type.replaced_by_id = @pricing_type.id
      orig_pricing_type.ineffective_on = DateTime.now
      orig_pricing_type.save!
      params[:comp_mult].each do |k, v|
        pc = PricingComponent.find_by_id(k)
        pc.multiplier = v
        pc.save
      end
      flash[:notice] = 'PricingType was successfully updated.'
      redirect_to({:action => "edit", :id => @pricing_type.id})
    else
      render :action => "edit"
    end
  end

  protected
  def make_a_table
    @table_name = params[:id]
    pd = PricingData.find_all_by_table_name(@table_name)
    cols = pd.map{|x| x.lookup_type}.uniq.sort
    rows = pd.map{|x| x.printme_value}.uniq.sort
    data = {}
    pd.each{|x|
      data[[x.lookup_type, x.printme_value]] = x.lookup_value
    }
    @table = [[@table_name, *cols]]
    rows.each do |row|
      @table << [row, *cols.map{|col| data[[col, row]]}]
    end
  end
  public

  def delete_table
    PricingData.delete_table(params[:id])
    redirect_to :action => 'index'
  end

  def show_table
    make_a_table
  end

  def to_csv
    make_a_table
    send_data @table.map{|x| gencsv(x)}.join(""), :type => 'text/csv; charset=utf-8; header=present', :disposition => "attachment; filename=#{params[:id]}.csv", :filename => "#{params[:id]}.csv"
  end

  def import_table
    @struct = OpenStruct.new(params[:open_struct])
    if @struct.csv
      PricingData.load_from_csv(@struct.name, @struct.csv.read)
      redirect_to :action => "show_table", :id => @struct.name
    else
      flash[:error] = "A CSV file to import must be uploaded"
      redirect_to :action => "index"
    end
  end

  def remove_expression
    pe = PricingExpression.find_by_id(params[:pricing_expression_id])
    pe.destroy
    redirect_to :action => "edit", :id => pe.pricing_type_id
  end

  def remove_term
    pe = PricingExpression.find_by_id(params[:pricing_expression_id])
    pe.pricing_components.delete(PricingComponent.find_by_id(params[:pricing_component_id]))
    redirect_to :action => "edit", :id => pe.pricing_type_id
  end

  def add_expression
    PricingExpression.new(:pricing_type_id => params[:pricing_type_id]).save
    redirect_to :action => "edit", :id => params[:pricing_type_id]
  end

  def add_term
    pe = PricingExpression.find_by_id(params[:pricing_expression_id])
    if params[:pricing_component_id]
      pe.pricing_components << PricingComponent.find_by_id(params[:pricing_component_id])
      redirect_to :action => "edit", :id => pe.pricing_type_id
    else
      @pricing_expression = pe
    end
  end

  def destroy
    @pricing_type = PricingType.find(params[:id])
    @pricing_type.ineffective_on = DateTime.now
    @pricing_type.save!

    redirect_to({:action => "index"})
  end
end
