class GizmoReturnsController < TransactionController
  before_filter :authorized_only, :except => ["destroy", "edit", "update"]
  before_filter :management_only, :only => ["destroy", "edit", "update"]

  def default_condition
    "created_at"
  end

  def index
    entry
    render :action => 'entry'
  end

  def entry
  end

  def new
    if [params[:gizmo_return][:sale_id], params[:gizmo_return][:disbursement_id]].map{|x| x.to_s}.select{|x| x != ""}.length != 1
      redirect_to :action => "entry", :gizmo_return => params[:gizmo_return], :error => "Please enter either a disbursement id or a sale id"
      return
    end
    if params[:gizmo_return][:sale_id].to_s != ""
      if ! Sale.find_by_id(params[:gizmo_return][:sale_id].to_i)
        redirect_to :action => "entry", :gizmo_return => params[:gizmo_return], :error => "Sale id is not valid"
        return
      end
    end
    if params[:gizmo_return][:disbursement_id].to_s != ""
      if ! Disbursement.find_by_id(params[:gizmo_return][:sale_id].to_i)
        redirect_to :action => "entry", :gizmo_return => params[:gizmo_return], :error => "Disbursement id is not valid"
        return
      end
    end
    super
  end

  protected

  def authorized_only
    requires_role('STORE', 'TECH_SUPPORT')
  end

  def management_only
    requires_role('STORE_ADMIN', 'BEAN_COUNTER')
  end
end
