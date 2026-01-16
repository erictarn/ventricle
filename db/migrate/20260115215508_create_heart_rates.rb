class CreateHeartRates < ActiveRecord::Migration[8.1]
  def change
    create_table :heart_rates do |t|
      t.references :monitoring_session
      t.integer :bpm
      t.datetime :start_time
      t.datetime :end_time
      t.integer :duration

      t.timestamps
    end
  end
end