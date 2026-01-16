class CreateMonitoringSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :monitoring_sessions do |t|
      t.references :user
      t.datetime :created_at
      t.integer :duration_in_secs
    end
  end
end
