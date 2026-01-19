Rails.application.config.after_initialize do
  # Skip during asset precompilation or when database doesn't exist
  unless Rails.env.test? || defined?(Rails::Console) || File.basename($0) == 'rake' || ENV['SECRET_KEY_BASE_DUMMY'].present?
    begin
      # Run synchronously to have cache ready immediately
      result = HeartRate.zone_percentage_distribution_sql
      Rails.cache.write("heart_rate_zone_percentage_distribution", result, expires_in: 12.hours)
      Rails.cache.write("heart_rate_zone_percentage_distribution_updated_at", Time.current, expires_in: 12.hours)
      Rails.logger.info "Zone distribution cache warmed up on startup: #{result}"
    rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError => e
      Rails.logger.warn "Skipping zone distribution cache warmup: #{e.message}"
    end
  end
end
