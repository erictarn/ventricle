namespace :csv_to_sql do
  desc "Generates SQL inserts from CSV for Users"
  task generate_users_sql: :environment do
    sql = "INSERT INTO users (id, created_at, username, gender, age, zone1_min, zone1_max, zone2_min, zone2_max, zone3_min, zone3_max, zone4_min, zone4_max) VALUES \n"
    sql += get_values_from_csv(Rails.root.join('db', 'seeds', 'csv_data', 'users.csv'))
    File.write(Rails.root.join("db", "insert_users.sql"), sql)
  end

  desc "Generates SQL inserts from CSV for Monitoring Sessions"
  task generate_monitoring_sessions_sql: :environment do
    sql = "INSERT INTO monitoring_sessions (id, user_id, created_at, duration_in_secs) VALUES \n"
    sql += get_values_from_csv(Rails.root.join('db', 'seeds', 'csv_data', 'hrm_sessions.csv'))
    File.write(Rails.root.join("db", "insert_monitoring_sessions.sql"), sql)
  end

  desc "Generates SQL inserts from CSV for Heart Rates"
  task generate_heart_rates_sql: :environment do
    sql = "INSERT INTO heart_rates (monitoring_session_id, bpm, start_time, end_time, duration_in_secs) VALUES \n"
    sql += get_values_from_csv(Rails.root.join('db', 'seeds', 'csv_data', 'hrm_data_points.csv'))
    File.write(Rails.root.join("db", "insert_heart_rates.sql"), sql)
  end

  def get_values_from_csv(filepath)
    batched_values_sql = Array.new

    CSV.foreach(filepath, headers: true) do |row|
      values = Array.new
      row.each do |header, value|
        values << ActiveRecord::Base.connection.quote(value)
      end
      batched_values_sql << "(#{ values.join(', ') })"
    end

    return batched_values_sql.join(", \n")
  end
end