class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :email
      t.string :subject
      t.string :query
      t.timestamp :last_run_at

      t.timestamps
    end
  end
end
