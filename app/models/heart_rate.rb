class HeartRate < ApplicationRecord
  belongs_to :monitoring_session

  # Class methods that gets the min, max, and avg heart rate for the whole db (db index added for performance)
  def self.min_bpm
    minimum(:bpm)
  end

  def self.max_bpm
    maximum(:bpm)
  end

  def self.avg_bpm
    average(:bpm)
  end

  # ActiveRecord too slow for 15m records, use the direct SQL method below, this method kept here for performance measurement curiosities
  def self.zone_percentage_distribution
    total_duration = 0
    zone_durations = { zone1: 0, zone2: 0, zone3: 0, zone4: 0, unzoned: 0 }

    # Use includes to avoid N+1 queries, find_each for batching with large datasets
    includes(monitoring_session: :user).find_each do |hr|
      next if hr.duration_in_secs.nil? || hr.bpm.nil?
      next if hr.monitoring_session.nil? || hr.monitoring_session.user.nil?

      user = hr.monitoring_session.user
      total_duration += hr.duration_in_secs

      # Determine which zone this heart rate falls into based on user's zones
      # Zone boundaries are inclusive on both min and max
      if hr.bpm >= user.zone1_min && hr.bpm <= user.zone1_max
        zone_durations[:zone1] += hr.duration_in_secs
      elsif hr.bpm >= user.zone2_min && hr.bpm <= user.zone2_max
        zone_durations[:zone2] += hr.duration_in_secs
      elsif hr.bpm >= user.zone3_min && hr.bpm <= user.zone3_max
        zone_durations[:zone3] += hr.duration_in_secs
      elsif hr.bpm >= user.zone4_min && hr.bpm <= user.zone4_max
        zone_durations[:zone4] += hr.duration_in_secs
      else
        zone_durations[:unzoned] += hr.duration_in_secs
      end
    end

    return {} if total_duration == 0

    # Calculate percentages
    {
      zone1: (zone_durations[:zone1].to_f / total_duration * 100).round(2),
      zone2: (zone_durations[:zone2].to_f / total_duration * 100).round(2),
      zone3: (zone_durations[:zone3].to_f / total_duration * 100).round(2),
      zone4: (zone_durations[:zone4].to_f / total_duration * 100).round(2),
      unzoned: (zone_durations[:unzoned].to_f / total_duration * 100).round(2)
    }
  end

  # Takes about 6 seconds before heart_rates composite index on bpm and duration_in_secs
  # Same after indexing b/c data is good, cached and externally update this processing intensive method HeartRate.zone_percentage_distribution_cached
  # The answer without both min/max inclusive bounds is {zone1: 1.52, zone2: 22.96, zone3: 38.08, zone4: 22.33, unzoned: 15.1}
  # The answer with both min/max inclusive bounds is {zone1: 1.97, zone2: 26.46, zone3: 40.74, zone4: 23.56, unzoned: 7.27}
  def self.zone_percentage_distribution_sql
    # Use SQL aggregation to calculate zone durations in the database
    # This is MUCH faster for large datasets (15M+ records)
    # Zone boundaries are inclusive on both min and max
    # That unzoned duration calculation is very Programmer logic vs domain logic (hr zones don't have gaps in between zones)
    result = joins(monitoring_session: :user)
      .where.not(bpm: nil).where.not(duration_in_secs: nil)
      .select(
        <<-SQL
          SUM(CASE
            WHEN heart_rates.bpm >= users.zone1_min AND heart_rates.bpm <= users.zone1_max
            THEN heart_rates.duration_in_secs
            ELSE 0
          END) as zone1_duration,
          SUM(CASE
            WHEN heart_rates.bpm >= users.zone2_min AND heart_rates.bpm <= users.zone2_max
            THEN heart_rates.duration_in_secs
            ELSE 0
          END) as zone2_duration,
          SUM(CASE
            WHEN heart_rates.bpm >= users.zone3_min AND heart_rates.bpm <= users.zone3_max
            THEN heart_rates.duration_in_secs
            ELSE 0
          END) as zone3_duration,
          SUM(CASE
            WHEN heart_rates.bpm >= users.zone4_min AND heart_rates.bpm <= users.zone4_max
            THEN heart_rates.duration_in_secs
            ELSE 0
          END) as zone4_duration,
          SUM(CASE
            WHEN (heart_rates.bpm < users.zone1_min OR heart_rates.bpm > users.zone4_max)
              AND (heart_rates.bpm < users.zone2_min OR heart_rates.bpm > users.zone2_max)
              AND (heart_rates.bpm < users.zone3_min OR heart_rates.bpm > users.zone3_max)
              AND (heart_rates.bpm < users.zone4_min OR heart_rates.bpm > users.zone4_max)
            THEN heart_rates.duration_in_secs
            ELSE 0
          END) as unzoned_duration,
          SUM(heart_rates.duration_in_secs) as total_duration
        SQL
      )
      .first

    return {} if result.nil? || result.total_duration.to_i == 0

    total = result.total_duration.to_f

    {
      zone1: (result.zone1_duration.to_f / total * 100).round(2),
      zone2: (result.zone2_duration.to_f / total * 100).round(2),
      zone3: (result.zone3_duration.to_f / total * 100).round(2),
      zone4: (result.zone4_duration.to_f / total * 100).round(2),
      unzoned: (result.unzoned_duration.to_f / total * 100).round(2)
    }
  end

  # Returns cached zone distribution, triggers background job if cache is empty
  def self.zone_percentage_distribution_cached
    cached_result = Rails.cache.read("heart_rate_zone_percentage_distribution")

    if cached_result.nil?
      # Cache miss - trigger background update and return empty for now
      UpdateZoneDistributionCacheJob.perform_later
      {}
    else
      cached_result
    end
  end

  # Manually trigger cache refresh via background job
  def self.refresh_zone_distribution_cache
    UpdateZoneDistributionCacheJob.perform_later
  end
end