class MeetingMindersController < ApplicationController
  layout "skedjulnator"
  protected
  public

  before_filter :update_skedjulnator_access_time

  def new
    @meeting_minder = MeetingMinder.new
    @meeting_minder.meeting_id = params[:meeting_id]
    @meeting_minder.subject = "%MEETING_NAME% Meeting Reminder"
  end

  def edit
    @meeting_minder = MeetingMinder.find(params[:id])
  end

  def show
    @meeting_minder = MeetingMinder.find(params[:id])
    @date = Date.parse(params[:date]) if params[:date]
  end

  def create
    @meeting_minder = MeetingMinder.new(params[:meeting_minder])

    if @meeting_minder.save
      flash[:notice] = 'MeetingMinder was successfully created.'
      redirect_to({:action => "list", :controller => "meetings"})
    else
      render :action => "new"
    end
  end

  def update
    @meeting_minder = MeetingMinder.find(params[:id])

    if @meeting_minder.update_attributes(params[:meeting_minder])
      flash[:notice] = 'MeetingMinder was successfully updated.'
      redirect_to({:action => "list", :controller => "meetings"})
    else
      render :action => "edit"
    end
  end

  def destroy
    @meeting_minder = MeetingMinder.find(params[:id])
    @meeting_minder.destroy

    redirect_to({:action => "list", :controller => "meetings"})
  end
end
