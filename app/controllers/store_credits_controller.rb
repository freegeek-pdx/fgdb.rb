class StoreCreditsController < ApplicationController

  layout :with_sidebar

  def index
    search
  end

  def search
    if !params[:conditions]
      params[:conditions] = {:created_at_enabled => "true"}
    end
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
#    if @conditions.contact_enabled
#      if !has_required_privileges('/view_contact_name')
#        return
#      end
#    end
    @credits = StoreCredit.paginate(:page => params[:page], :conditions => @conditions.conditions(StoreCredit), :order => "store_credits.created_at ASC", :per_page => 50)
    render :action => "index"
  end

  def history
    tid = -1
    begin
      tid = StoreChecksum.new_from_checksum(params[:id]).result # what I'm after here
    rescue StoreChecksumException
    end
    s = StoreCredit.find_by_id(tid)
    @credits = s ? s.all_instances : []
  end
end
