class AddCompositeIndexToHeartRates < ActiveRecord::Migration[8.1]
  def change
    add_index :heart_rates, [:bpm, :duration_in_secs]
  end
end
