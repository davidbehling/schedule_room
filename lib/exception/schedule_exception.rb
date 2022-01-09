# frozen_string_literal: true

module ScheduleException
  class Base < StandardError
    def initialize(message = 'Unexpected error')
      super(message)
    end
  end

  class MeetingScheduleNotFoundError < Base
    def initialize(message = 'schedule not found')
      super(message)
    end
  end

  class TimeError < Base
    def initialize(message = 'time error')
      super(message)
    end
  end

  class NumberRoomError < Base
    def initialize(message = 'number room error')
      super(message)
    end
  end

  class ScheduleNotAllowed < Base
    def initialize(message = 'scheduling not allowed')
      super(message)
    end
  end

  class WeekDaysError < Base
    def initialize(message = 'no appointments allowed for saturdays and sundays')
      super(message)
    end
  end

  class InvalidDateError < Base
    def initialize(message = 'invalid date format. valid format YYYY-MM-DD')
      super(message)
    end
  end

  class StartTimeGreaterThanEndTimeError < Base
    def initialize(message = 'start time can not be greater than end time')
      super(message)
    end
  end

  class OutOfHoursError < Base
    def initialize(message = 'The appointment must be between 9:00 am to 6:00 pm')
      super(message)
    end
  end
end
