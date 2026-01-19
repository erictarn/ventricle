Rails.application.config.after_initialize do
  unless Rails.env.test? || defined?(Rails::Console) || File.basename($0) == 'rake'
    # Run synchronously to have cache ready immediately
    result = HeartRate.zone_percentage_distribution_sql
    Rails.cache.write("heart_rate_zone_percentage_distribution", result, expires_in: 1.hour)
    Rails.cache.write("heart_rate_zone_percentage_distribution_updated_at", Time.current, expires_in: 1.hour)
    Rails.logger.info "Zone distribution cache warmed up on startup: #{result}"
  end
end
