class AddUniqueConstraintToNotifications < ActiveRecord::Migration
  def change
    add_index :notifications, [:email, :query], :unique => true
  end
end
