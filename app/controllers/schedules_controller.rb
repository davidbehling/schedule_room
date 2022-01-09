class SchedulesController < ApplicationController
  rescue_from(StandardError) do |exception|
    Rails.logger.error "SchedulesController: failed_request_response\n#{exception.message}\n#{exception.backtrace.join("\n")}"
    if exception.is_a?(ScheduleException::Base) || !Rails.env.production?
        failed_request_response(exception.message)
    else
        failed_request_response('Unexpected Error')
    end
  end

  def list
    schedules = schedule_svc.list(params)
    render json: schedules
  end

  def list_by_date
    schedules = schedule_svc.list_by_date(params[:date].to_datetime)
    render json: schedules
  end

  def list_by_number_room
    schedules = schedule_svc.list_by_number_room(params[:number_room])
    render json: schedules
  end
    
  def list_by_date_and_number_room
    schedules = schedule_svc.list_by_date_and_number_room(params[:date].to_datetime, params[:number_room])
    render json: schedules
  end

  def find_schedule
    schedule = Schedule.find(params[:id])
    render json: schedule_svc.convert_model_in_object(schedule)
  end

  def destroy_schedule
    Schedule.destroy(params[:id])
    render json: { status: "ok" }
  end

  def create_schedule
    schedule = schedule_svc.create(params.permit(:number_room, :date, :start_time, :end_time))
    render json: schedule
  end

  def update_schedule
    schedule = schedule_svc.update(params.permit(:id, :number_room, :date, :start_time, :end_time))
    render json: schedule
  end
    
  private
    
  def schedule_svc
    @schedule_svc ||= ScheduleService.new
  end
    
  def failed_request_response(message, status_message: 'internal_server_error', status_code: :internal_server_error)
    render json: { status: status_message, message: message , status: status_code }
  end
end
