class CreateSchedules < ActiveRecord::Migration[6.1]
  def change
    create_table :schedules do |t|
      t.integer :number_room
      t.datetime :date
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end
