puts "rails db:seed MODEL={users|heart_rates|all}"

model = ENV['MODEL'] || 'all'

case model
when 'users'
  load Rails.root.join('db', 'seeds', 'users.rb')
when 'heart_rates'
  load Rails.root.join('db', 'seeds', 'heart_rates.rb')
when 'all'
  load Rails.root.join('db', 'seeds', 'users.rb')
  load Rails.root.join('db', 'seeds', 'heart_rates.rb')
else
  puts "Unknown Model: #{model}"
  puts "Available: users, heart_rates, all"
end