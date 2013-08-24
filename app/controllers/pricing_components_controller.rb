class PricingComponentsController < ApplicationController
  layout :with_sidebar

  protected

  def prep_table_headers
    @pricing_values = @pricing_component.pricing_values
    header = ['ID', 'Name']
    if @pricing_component and @pricing_component.pull_from
    if @pricing_component.numerical?
      header << 'Minimum'
      header << 'Maximum'
    else
      header << 'Matcher'
      end
      end
    header << 'Value'
    @table = [header]
  end

  def make_a_table
    prep_table_headers
    for pricing_value in @pricing_values
      p = [pricing_value.id]
      p << pricing_value.name
      if @pricing_component and @pricing_component.pull_from
        if @pricing_component.numerical?
          p << pricing_value.minimum
          p << pricing_value.maximum
        else
          p << pricing_value.matcher
        end
      end
      p << pricing_value.value
      @table << p
    end
  end
  public

  def to_csv
    @pricing_component = PricingComponent.find(params[:id])
    make_a_table
    send_data @table.map{|x| x.shift; gencsv(x)}.join(""), :type => 'text/csv; charset=utf-8; header=present', :disposition => "attachment; filename=#{@pricing_component.name}.csv", :filename => "#{@pricing_component.name}.csv"
  end

  def import_table
    @pricing_component = PricingComponent.find(params[:id])
    prep_table_headers
    @struct = OpenStruct.new(params[:open_struct])
    if ! @struct.csv
      flash[:error] = "A file to import must be uploaded"
      redirect_to :action => "edit", :id => @pricing_component.id
    end
    results = CSV.parse(@struct.csv.read)
    if results[0] == @table[0][1..-1]
      @pricing_component.pricing_values.destroy_all
      header = results.shift
      results.each{|args|
        h = {}
        args.each_with_index {|x,i|
          h[header[i]] = x
        }
        h['Maximum'] = h['Maximum'].to_i if header.include?('Maximum')
        h['Minimum'] = h['Minimum'].to_i if header.include?('Minimum')
        h['Value'] = h['Value'].to_s if header.include?('Value')
        PricingValue.new(:pricing_component => @pricing_component, :name => h['Name'], :matcher => h['Matcher'], :minimum => h['Minimum'], :maximum => h['Maximum'], :value => h['Value']).save
        # just process it
      }
      redirect_to :action => "edit", :id => @pricing_component.id
    else
      flash[:error] = "The column headers(#{results[0].join(", ")}) did not match expected: #{@table[0][1..-1].join(", ")}"
      redirect_to :action => "edit", :id => @pricing_component.id
    end
  end

  def new
    @pricing_expression = PricingExpression.find(params[:pricing_expression_id])
    @pricing_component = PricingComponent.new
    @pricing_component.pricing_expressions << @pricing_expression
  end

  def edit
    session[:pricing_refer] = request.env["HTTP_REFERER"]
    @pricing_component = PricingComponent.find(params[:id])
    make_a_table
  end

  def create
    @pricing_expression = PricingExpression.find(params[:pricing_expression_id])
    @pricing_component = PricingComponent.new(params[:pricing_component])
    @pricing_component.pricing_expressions << @pricing_expression

    if @pricing_component.save
      flash[:notice] = 'PricingComponent was successfully created.'
      redirect_to({:action => "edit", :controller => "pricing_types", :id => @pricing_expression.pricing_type.id})
    else
      render :action => "new"
    end
  end

  def update
    @pricing_component = PricingComponent.find(params[:id])

    if @pricing_component.update_attributes(params[:pricing_component])
      flash[:notice] = 'PricingComponent was successfully updated.'
      redirect_to(session[:pricing_refer] || {:controller => "pricing_types"})
      session.delete(:pricing_refer)
    else
      render :action => "edit"
    end
  end

  def destroy
    @pricing_component = PricingComponent.find(params[:id])
    @pricing_component.destroy

    redirect_to({:action => "index", :controller => "pricing_types"})
  end
end
