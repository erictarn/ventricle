class UpdateZoneDistributionCacheJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting zone distribution cache update..."
    start_time = Time.now

    result = HeartRate.zone_percentage_distribution_sql
    Rails.cache.write("heart_rate_zone_percentage_distribution", result, expires_in: 1.hour)

    elapsed = Time.now - start_time
    Rails.logger.info "Zone distribution cache updated in #{elapsed.round(2)} seconds: #{result}"

    result
  end
end
