class Notification < ActiveRecord::Base
  before_create :set_last_run_at_to_now

  validates :query, uniqueness: { scope: :email, message: " already exists for the selected email"}

  def set_last_run_at_to_now
    self.last_run_at = Time.now
  end

  def self.process_all
    Notification.all.each &:process
  end

  def process
    formatted_time = last_run_at.strftime("%Y-%m-%dT%H:%M.%6NZ")
    log_entries_query = "#{self.query} @timestamp:{#{formatted_time} TO *}"
    items = Hercule::LogEntry.query(log_entries_query).items
    self.last_run_at = Time.now
    self.save!

    if items.length > 0
      activities = items.map(&:activity).uniq
      NotificationMailer.notification_email(self, activities).deliver
    end
  end
end
