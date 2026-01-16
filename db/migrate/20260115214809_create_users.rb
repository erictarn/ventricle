class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.datetime :created_at
      t.string :username
      t.string :gender
      t.integer :age
      t.integer :zone1_min
      t.integer :zone1_max
      t.integer :zone2_min
      t.integer :zone2_max
      t.integer :zone3_min
      t.integer :zone3_max
      t.integer :zone4_min
      t.integer :zone4_max

      t.index :username, unique: true #notable
    end
  end
end