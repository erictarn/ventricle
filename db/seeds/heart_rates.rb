puts 'Seeding HeartRates...'

MONITORING_SESSION_CSV_FILE = Rails.root.join('db', 'seeds', 'csv_data', 'hrm_sessions.csv')
# MONITORING_SESSION_CSV_FILE = Rails.root.join('db', 'seeds', 'csv_data', 'hrm_sessions.csv.trunc') #notable
HR_DATA_POINTS_CSV_FILE = Rails.root.join('db', 'seeds', 'csv_data', 'hrm_data_points.csv')
# HR_DATA_POINTS_CSV_FILE = Rails.root.join('db', 'seeds', 'csv_data', 'hrm_data_points.csv.trunc') #notable
HR_DATA_POINTS = CSV.read(HR_DATA_POINTS_CSV_FILE, headers: true)

ms_success_count = 0
ms_error_count = 0

MonitoringSession.destroy_all
HeartRate.destroy_all

# Creates all of the HeartRate records for one MonitoringSession
def create_hr_records(csv_session_id, monitoring_session_id)
  hr_success_count = 0
  hr_error_count = 0

  hrm_data_point_records = HR_DATA_POINTS.select { |data_point_row| data_point_row['Session ID'] == csv_session_id }

  # Note the switch from import data Session ID to own internal MonitoringSession.id
  hrm_data_point_records.each do |row|
    hr = HeartRate.new(
      monitoring_session_id: monitoring_session_id,
      bpm: row['Beats Per Minute'],
      start_time: row['Reading Start Time'],
      end_time: row['Reading End Time'],
      duration: row['Duration in Secs']
    )

    if hr.save
      hr_success_count += 1
    else
      hr_error_count += 1
      puts "HeartRate Error: #{ hr.errors.full_messages.join(", ") }"
    end
  end

  puts "Successfully created #{hr_success_count} HeartRates"
  puts "Failed to create #{hr_error_count} HeartRates" if hr_error_count > 0
end

CSV.foreach(MONITORING_SESSION_CSV_FILE, headers: true) do |session_row|
  ms = MonitoringSession.new(
    user_id: session_row['User Id'],
    created_at: session_row['Created At'],
    duration: session_row['Duration in Secs']
  )

  if ms.save
    ms_success_count += 1
  else
    ms_error_count += 1
    puts "Error: #{ ms.errors.full_messages.join(", ") }"
  end

  create_hr_records(session_row['Session ID'], ms.id)
end

puts "Successfully created #{ms_success_count} MonitoringSessions"
puts "Failed to create #{ms_error_count} MonitoringSessions" if ms_error_count > 0