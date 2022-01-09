# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchedulesController, type: :request do
  before :all do
    @schedule_a = Schedule.create(number_room: 1, date: "2022-01-10", start_time: "13:00", end_time: "16:00")
    @schedule_b = Schedule.create(number_room: 1, date: "2022-01-10", start_time: "10:00", end_time: "11:00")
    @schedule_c = Schedule.create(number_room: 1, date: "2022-01-11", start_time: "10:00", end_time: "11:00")
    @schedule_d = Schedule.create(number_room: 2, date: "2022-01-10", start_time: "10:00", end_time: "11:00")
  end

  it "find_schedule" do
    get "/schedules/find_schedule", params: { id: @schedule_a.id }
    expect(JSON.parse(response.body)["id"]).to eq(@schedule_a.id)
  end

  it "create_schedule" do
    expect {
      post "/schedules/create_schedule", params: { number_room: 3, date: "2022-01-06", start_time: "09:00", end_time: "18:00" }
    }.to change(Schedule, :count).by(1)
  end

  it "update_schedule" do
    old_number_room = @schedule_a.number_room
    old_date = @schedule_a.date
    old_start_time = @schedule_a.start_time
    old_end_time = @schedule_a.end_time

    put "/schedules/update_schedule", params: { id: @schedule_a.id, number_room: 2, date: "2022-01-11", start_time: "14:00", end_time: "15:00" }

    @schedule_a.reload

    expect(
      old_number_room != @schedule_a.number_room &&
      old_date != @schedule_a.date &&
      old_start_time != @schedule_a.start_time &&
      old_end_time != @schedule_a.end_time
    ).to eq(true)
  end
  
  it "destroy_schedule" do
    expect {
      delete "/schedules/destroy_schedule", params: { id: @schedule_d.id }
    }.to change(Schedule, :count).by(-1)
  end
end
