# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduleService, type: :service do
  before :all do
    @schedule_service ||= ScheduleService.new
  end

  it "number_room não pode ser nulo" do
    params = { number_room: nil, date: "2022-01-01", start_time: "12:00", end_time: "18:00" }
    expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::NumberRoomError)
  end

  describe "date" do
    it "date válido" do
      params = { number_room: 1, date: "2022-01-06", start_time: "09:00", end_time: "18:00" }
      expect(@schedule_service.validate(params)).to be_nil
    end

    ["a", "1", "2022-13-01", "2022-00-01", "01-01-2001", "2022/01/01", "01/01/2022", "2022-01-00", "13:30"].each do |date|
      it "data invalida: #{date}" do
        params = { number_room: 1, date: date, start_time: "12:00", end_time: "18:00" }
        expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::InvalidDateError)
      end
    end

    ["2022-02-30", "2022-11-31"].each do |date|
      it "data invalida: #{date}" do
        params = { number_room: 1, date: date, start_time: "12:00", end_time: "18:00" }
        expect { @schedule_service.validate(params) }.to raise_error(Date::Error)
      end
    end

    [["sabado", "2022-01-08"], ["domingo", "2022-01-09"]].each do |date|
      it "não pode fazer agendamento no #{date[0]}" do
        params = { number_room: 1, date: date[1], start_time: "12:00", end_time: "18:00" }
        expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::WeekDaysError)
      end
    end
  end

  describe "times" do
    it "start_time end end_time válidos" do
      params = { number_room: 1, date: "2022-01-06", start_time: "09:00", end_time: "18:00" }
      expect(@schedule_service.validate(params)).to be_nil
    end

    ["a", "13", "25:01", "13:60", "12:30:59"].each do |time|
      it "start_time inválido #{time}" do
        params = { number_room: 1, date: "2022-01-06", start_time: time, end_time: "18:00" }
        expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::TimeError)
      end
    end

    ["a", "13", "25:01", "13:60", "12:30:59"].each do |time|
      it "end_time inválido #{time}" do
        params = { number_room: 1, date: "2022-01-06", start_time: "10:00", end_time: time }
        expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::TimeError)
      end
    end

    it "start_time não pode ser nulo" do
      params = { number_room: 1, date: "2022-01-06", start_time: nil, end_time: "18:00" }
      expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::TimeError)
    end

    it "end_time não pode ser nulo" do
      params = { number_room: 1, date: "2022-01-06", start_time: "09:01", end_time: nil }
      expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::TimeError)
    end

    it "start_time não pode ser antes das 09:00" do
      params = { number_room: 1, date: "2022-01-06", start_time: "08:59", end_time: "18:00" }
      expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::OutOfHoursError)
    end

    it "end_time não pode ser depois das 18:00" do
      params = { number_room: 1, date: "2022-01-06", start_time: "09:00", end_time: "18:01" }
      expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::OutOfHoursError)
    end

    it "start_time não pode ser maior que end_time" do
      params = { number_room: 1, date: "2022-01-06", start_time: "11:00", end_time: "10:00" }
      expect { @schedule_service.validate(params) }.to raise_error(ScheduleException::StartTimeGreaterThanEndTimeError)
    end
  end

  describe "verific_schedule" do
    before do
      @schedule_a = Schedule.create(number_room: 1, date: "2022-01-10", start_time: "13:00", end_time: "16:00")
      @schedule_b = Schedule.create(number_room: 1, date: "2022-01-10", start_time: "10:00", end_time: "11:00")
    end

    it "sucesso ao agendar horário das 12:00 as 12:59" do
      params = { number_room: 1, date: "2022-01-10", start_time: "12:00", end_time: "12:59" }
      expect(@schedule_service.verific_schedule(params)).to be_nil
    end

    it "sucesso ao agendar horário das 16:01 as 18:00" do
      params = { number_room: 1, date: "2022-01-10", start_time: "16:01", end_time: "18:00" }
      expect(@schedule_service.verific_schedule(params)).to be_nil
    end

    it "sucesso ao agendar o mesmo horario de schedule_a em uma data diferente" do
      params = { number_room: 1, date: "2022-01-11", start_time: "13:00", end_time: "16:00" }
      expect(@schedule_service.verific_schedule(params)).to be_nil
    end

    it "sucesso ao agendar o mesmo horario de schedule_a em uma sala diferente" do
      params = { number_room: 2, date: "2022-01-10", start_time: "13:00", end_time: "16:00" }
      expect(@schedule_service.verific_schedule(params)).to be_nil
    end

    it "erro ao agendar, schedule_a já possue esse horário" do
      params = { number_room: 1, date: "2022-01-10", start_time: "13:00", end_time: "16:00" }
      expect { @schedule_service.verific_schedule(params) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao agendar, existe um hoŕario dentro desse período" do
      params = { number_room: 1, date: "2022-01-10", start_time: "12:00", end_time: "18:00" }
      expect { @schedule_service.verific_schedule(params) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao agendar, existe um horário que inicia antes e encerra depois desse período" do
      params = { number_room: 1, date: "2022-01-10", start_time: "14:00", end_time: "15:00" }
      expect { @schedule_service.verific_schedule(params) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao agendar, 14:00 já esta ocupado" do
      params = { number_room: 1, date: "2022-01-10", start_time: "14:00", end_time: "18:00" }
      expect { @schedule_service.verific_schedule(params) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao agendar, 15:00 já esta ocupado" do
      params = { number_room: 1, date: "2022-01-10", start_time: "12:00", end_time: "15:00" }
      expect { @schedule_service.verific_schedule(params) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao agendar, 13:00 já esta ocupado" do
      params = { number_room: 1, date: "2022-01-10", start_time: "12:00", end_time: "13:00" }
      expect { @schedule_service.verific_schedule(params) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao agendar, 16:00 já esta ocupado" do
      params = { number_room: 1, date: "2022-01-10", start_time: "16:00", end_time: "17:00" }
      expect { @schedule_service.verific_schedule(params) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    [
      { start_time: "12:00", end_time: "18:00" },
      { start_time: "14:00", end_time: "15:00" },
      { start_time: "14:00", end_time: "18:00" },
      { start_time: "12:00", end_time: "15:00" },
      { start_time: "12:00", end_time: "13:00" },
      { start_time: "16:00", end_time: "17:00" },
    ].each do |time|
      it "sucesso ao reagendar horário de schedule_a, das #{time[:start_time]} as #{time[:end_time]}" do
        params = { number_room: 1, date: "2022-01-10", start_time: time[:start_time], end_time: time[:end_time] }
        expect(@schedule_service.verific_schedule(params, @schedule_a)).to be_nil
      end
    end

    it "erro ao reagendar, schedule_b já possue esse horário" do
      params = { number_room: 1, date: "2022-01-10", start_time: "10:00", end_time: "11:00" }
      expect { @schedule_service.verific_schedule(params, @schedule_a) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao reagendar, existe um hoŕario dentro desse período" do
      params = { number_room: 1, date: "2022-01-10", start_time: "09:00", end_time: "12:00" }
      expect { @schedule_service.verific_schedule(params, @schedule_a) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao reagendar, existe um horário que inicia antes e encerra depois desse período" do
      params = { number_room: 1, date: "2022-01-10", start_time: "10:15", end_time: "10:50" }
      expect { @schedule_service.verific_schedule(params, @schedule_a) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao reagendar, 10:15 já esta ocupado" do
      params = { number_room: 1, date: "2022-01-10", start_time: "10:15", end_time: "12:00" }
      expect { @schedule_service.verific_schedule(params, @schedule_a) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao reagendar, 10:50 já esta ocupado" do
      params = { number_room: 1, date: "2022-01-10", start_time: "09:00", end_time: "10:50" }
      expect { @schedule_service.verific_schedule(params, @schedule_a) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao reagendar, 10:00 já esta ocupado" do
      params = { number_room: 1, date: "2022-01-10", start_time: "09:00", end_time: "10:00" }
      expect { @schedule_service.verific_schedule(params, @schedule_a) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end

    it "erro ao reagendar, 11:00 já esta ocupado" do
      params = { number_room: 1, date: "2022-01-10", start_time: "11:00", end_time: "12:00" }
      expect { @schedule_service.verific_schedule(params, @schedule_a) }.to raise_error(ScheduleException::ScheduleNotAllowed)
    end
  end
end
