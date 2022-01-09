# frozen_string_literal: true

class ScheduleService

  def create(params)
    validate(params)

    params = convert_date_and_time_to_datetime(params)

    verific_schedule(params)

    schedule = Schedule.create(params)

    convert_model_in_object(schedule)
  end
  
  def update(params)
    validate(params)

    params = convert_date_and_time_to_datetime(params)    

    schedule = Schedule.find(params[:id])

    verific_schedule(params, schedule)

    schedule.update(params)

    convert_model_in_object(schedule.reload)
  end

  def list(params)
    schedules = Schedule.all.order(date: :asc).order(number_room: :asc).order(start_time: :asc)
    schedules.map { |schedule| convert_model_in_object(schedule) }
  end
  
  def list_by_date(date)
    schedules = Schedule.where(date: date).order(number_room: :asc).order(start_time: :asc)
    schedules.map { |schedule| convert_model_in_object(schedule) }
  end

  def list_by_number_room(number_room)
    schedules = Schedule.where(number_room: number_room).order(date: :asc).order(start_time: :asc)
    schedules.map { |schedule| convert_model_in_object(schedule) }
  end

  def list_by_date_and_number_room(date, number_room)
    schedules = Schedule.where(date: date, number_room: number_room).order(number_room: :asc).order(start_time: :asc)
    schedules.map { |schedule| convert_model_in_object(schedule) }
  end
  
  def verific_schedule(params, old_schedule = nil)
    schedule = Schedule.where(number_room: params[:number_room], date: params[:date])
    schedule = schedule.where.not(id: old_schedule.id) if old_schedule.present?
    return if schedule.blank?

    start_time = params[:start_time].to_datetime
    end_time = params[:end_time].to_datetime

    raise ScheduleException::ScheduleNotAllowed if schedule.where(start_time: start_time..end_time).present?
    raise ScheduleException::ScheduleNotAllowed if schedule.where(end_time: start_time..end_time).present?

    time = schedule.where(start_time: ("09:00".to_datetime)..start_time).order(start_time: :asc).last
    raise ScheduleException::ScheduleNotAllowed if time.present? && time.end_time > params[:end_time].to_datetime
  end
  
  def convert_date_and_time_to_datetime(params)
    params[:date] = params[:date].to_datetime
    params[:start_time] = params[:start_time].to_datetime
    params[:end_time] = params[:end_time].to_datetime
    params
  end

  def convert_model_in_object(schedule)
    { 
      id:          schedule.id,
      number_room: schedule.number_room,
      date:        schedule.date.strftime("%Y-%m-%d"),
      start_time:  schedule.start_time.to_s(:time),
      end_time:    schedule.end_time.to_s(:time)
    }
  end
  
  def is_time?(value)
    (value =~ /^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/).present?
  end

  def valide_format_date?(value)
    (value =~ /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/).present?
  end
  
  def validate(params)
    raise ScheduleException::NumberRoomError if params[:number_room].blank?
    raise ScheduleException::InvalidDateError if !valide_format_date?(params[:date])
    raise ScheduleException::WeekDaysError if [0, 6].include?(params[:date].to_datetime.wday)
    raise ScheduleException::TimeError if !is_time?(params[:start_time])
    raise ScheduleException::TimeError if !is_time?(params[:end_time])
    raise ScheduleException::StartTimeGreaterThanEndTimeError if params[:start_time].to_datetime > params[:end_time].to_datetime

    start_time = "09:00".to_datetime
    end_time = "18:00".to_datetime

    if start_time > params[:start_time].to_datetime || end_time < params[:end_time].to_datetime
      raise ScheduleException::OutOfHoursError
    end
  end
end
