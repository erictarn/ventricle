class AddIndexToHeartRatesBpm < ActiveRecord::Migration[8.1]
  def change
    add_index :heart_rates, :bpm
  end
end
