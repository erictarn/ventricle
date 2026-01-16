puts 'Seeding Users...'

User.destroy_all

u_csv_file = Rails.root.join('db', 'seeds', 'csv_data', 'users.csv')

u_success_count = 0
u_error_count = 0

CSV.foreach(u_csv_file, headers: true) do |row|
  u = User.new(
    id: row['User ID'],
    created_at: row['Created At'],
    username: row['Username'],
    gender: row['Gender'],
    age: row['Age'],
    zone1_min: row['HR Zone1 BPM Min'],
    zone1_max: row['HR Zone1 BPM Max'],
    zone2_min: row['HR Zone2 BPM Min'],
    zone2_max: row['HR Zone2 BPM Max'],
    zone3_min: row['HR Zone3 BPM Min'],
    zone3_max: row['HR Zone3 BPM Max'],
    zone4_min: row['HR Zone4 BPM Min'],
    zone4_max: row['HR Zone4 BPM Max']
  )

  if u.save
    u_success_count += 1
  else
    u_error_count += 1
    puts "Error: #{u.errors.full_messages.join(', ')}"
  end
end

puts "Successfully created #{u_success_count} Users"
puts "Failed to create #{u_error_count} Users" if u_error_count > 0