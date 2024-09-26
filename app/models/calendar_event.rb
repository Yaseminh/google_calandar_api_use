class CalendarEvent < ApplicationRecord
  validates :summary, :start_time, :end_time, :description, presence: true
  belongs_to :user
end
