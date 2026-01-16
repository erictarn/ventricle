class CreateHeartRates < ActiveRecord::Migration[8.1]
  def change
    create_table :heart_rates do |t|
      t.references :monitoring_session
      t.integer :bpm
      t.datetime :start_time
      t.datetime :end_time
      t.integer :duration_in_secs
    end
  end
end