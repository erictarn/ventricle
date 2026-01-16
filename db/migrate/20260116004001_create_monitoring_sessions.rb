class CreateMonitoringSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :monitoring_sessions do |t|
      t.references :user
      t.integer :duration

      t.timestamps
    end
  end
end
