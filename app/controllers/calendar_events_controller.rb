class CalendarEventsController < ApplicationController
  before_action :load_event, only: %i[destroy edit update show]  # 'show' aksiyonunu ekleyin
  def index
    @calendar_events = current_user.calendar_events.order(updated_at: :desc)

    puts @calendar_events.inspect
  end

  def new
    @calendar_event = current_user.calendar_events.new
  end

  def create
    # @calendar_event = current_user.events.new(event_params)
    @calendar_event = current_user.calendar_events.new(
      summary: params[:summary],
      description: params[:description],
      start_time: params[:start_time],  # start_time yerine start
      end_time: params[:end_time],      # end_time yerine end
      user_id: params[:user_id],
    #authenticity_token:params[:authenticity_token]
      )
    if  @calendar_event.save

      GoogleCalender::EventScheduler.new(current_user,  @calendar_event).register_event

      flash[:success] = t(:successfully_created, scope: :event)
      redirect_to 'http://localhost:3000/'
    else
      flash[:error] = t(:something_went_wrong, scope: :event)
      render :new
    end
  end

  def edit; end

  def update
    if @calendar_event.update(event_params)
      GoogleCalender::EventScheduler.new(current_user, @calendar_event).update_event
      flash[:notice] = t(:successfully_updated, scope: :calendar_event)
      redirect_to calendar_events_path
    else
      flash.now[:error] = @calendar_event.errors.full_messages.join(', ')
      render :edit
    end
  end

  def destroy
    GoogleCalender::EventScheduler.new(current_user, @calendar_event).delete_event
    @calendar_event.destroy
    redirect_to calendar_events_path, notice: 'Event was successfully destroyed.'
  end

  def show
    # Burada genellikle başka bir işleme gerek yok; @calendar_event zaten yüklü.
  end

  private

  def load_event
    @calendar_event = current_user.calendar_events.find(params[:id])
  end

  def event_params
    params.require(:calendar_event).permit(:summary, :start_time, :end_time, :description,:user_id)
  end
end
