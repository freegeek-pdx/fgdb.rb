class DisktestBatchesController < ApplicationController
  protected
  def get_required_privileges
    a = super
    a << {:privileges => ['data_security']}
    a
  end
  public

#  def update_all_drives
#    @disktest_batch = DisktestBatch.find_by_id(params[:id]) || DisktestBatch.new(:date => Date.today)
#    @drives = params.to_a.select{|x,y| ![:action, :id, :controller].include?(x)}
#    render :update do |page|
#      page.hide loading_indicator_id("batch_drive_line")
#      @drives.each do |key, serial|
#        page << "$(#{key.to_s}).getElementsByClassName('status')[0].getElementsByTagName('input')[0].value = #{@disktest_batch.fake_status(serial).to_json};"
#      end
#      page << "document.getElementsByTagName('form')[0].enable();"
#    end
#  end

  def update_a_drive
    @disktest_batch = DisktestBatch.find_by_id(params[:id]) || DisktestBatch.new(:date => Date.today)
    render :update do |page|
      page.hide loading_indicator_id("batch_drive_line")
      page << "updated_status = #{@disktest_batch.fake_status(params[:serial_number]).to_json};"
      page << "document.getElementsByTagName('form')[0].enable();"
    end
  end

  layout :with_sidebar

  def search
    @error = params[:error]
    if !params[:conditions]
      params[:conditions] = {:finalized_enabled => "true", :finalized_excluded => "true"}
    end
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    @disktest_batches = DisktestBatch.paginate(:page => params[:page], :conditions => @conditions.conditions(DisktestBatch), :order => "created_at ASC", :per_page => 50)
    render :action => "index"
  end

  def index
    search
  end

  def show
    @disktest_batch = DisktestBatch.find(params[:id])
  end

  def new
    @disktest_batch = DisktestBatch.new
    @disktest_batch.date = Date.today
  end

  def edit
    @disktest_batch = DisktestBatch.find(params[:id])
  end

  def create
    @disktest_batch = DisktestBatch.new(params[:disktest_batch])

    my_apply_line_item_data(@disktest_batch, 'disktest_batch_drives', 'drives')

    if @disktest_batch.save
      flash[:notice] = 'DisktestBatch was successfully created.'
      redirect_to({:action => "show", :id => @disktest_batch.id})
    else
      render :action => "new"
    end
  end

  def update
    @disktest_batch = DisktestBatch.find(params[:id])
    # FIXME: consolidate these..
    my_apply_line_item_data(@disktest_batch, 'disktest_batch_drives', 'drives')

    if @disktest_batch.update_attributes(params[:disktest_batch])
      @disktest_batch.disktest_batch_drives.each do |dbb|
        dbb.save
      end
      flash[:notice] = 'DisktestBatch was successfully updated.'
      redirect_to({:action => "show", :id => @disktest_batch.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @disktest_batch = DisktestBatch.find(params[:id])
    @disktest_batch.destroy

    redirect_to({:action => "index"})
  end
end
