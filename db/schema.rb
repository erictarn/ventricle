# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_17_231256) do
  create_table "heart_rates", force: :cascade do |t|
    t.integer "bpm"
    t.integer "duration_in_secs"
    t.datetime "end_time"
    t.integer "monitoring_session_id"
    t.datetime "start_time"
    t.index ["bpm", "duration_in_secs"], name: "index_heart_rates_on_bpm_and_duration_in_secs"
    t.index ["bpm"], name: "index_heart_rates_on_bpm"
    t.index ["monitoring_session_id"], name: "index_heart_rates_on_monitoring_session_id"
  end

  create_table "monitoring_sessions", force: :cascade do |t|
    t.datetime "created_at"
    t.integer "duration_in_secs"
    t.integer "user_id"
    t.index ["user_id"], name: "index_monitoring_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "age"
    t.datetime "created_at"
    t.string "gender"
    t.string "username"
    t.integer "zone1_max"
    t.integer "zone1_min"
    t.integer "zone2_max"
    t.integer "zone2_min"
    t.integer "zone3_max"
    t.integer "zone3_min"
    t.integer "zone4_max"
    t.integer "zone4_min"
    t.index ["username"], name: "index_users_on_username", unique: true
  end
end
