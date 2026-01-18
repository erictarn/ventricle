class MonitoringSession < ApplicationRecord
  belongs_to :user
  has_many :heart_rates, dependent: :destroy

  def min_hr
    HeartRate.where(monitoring_session_id: id).minimum(:bpm)
  end

  def max_hr
    HeartRate.where(monitoring_session_id: id).maximum(:bpm)
  end

  def avg_hr
    HeartRate.where(monitoring_session_id: id).average(:bpm) #Returns BigDecimal, to_f for formatting
  end

  def zone_durations
    return {} if user.nil? #Assume data integrity

    zones = {
      zone1: { min: user.zone1_min, max: user.zone1_max, duration: 0 },
      zone2: { min: user.zone2_min, max: user.zone2_max, duration: 0 },
      zone3: { min: user.zone3_min, max: user.zone3_max, duration: 0 },
      zone4: { min: user.zone4_min, max: user.zone4_max, duration: 0 }
    }

    heart_rates.each do |hr|
      next if hr.bpm.nil? || hr.duration_in_secs.nil?

      zones.each do |zone_name, zone_data|
        # Zone boundaries are inclusive on both min and max
        if hr.bpm >= zone_data[:min] && hr.bpm <= zone_data[:max]
          zone_data[:duration] += hr.duration_in_secs
          break
        end
      end
    end

    # Return just the durations
    {
      zone1: zones[:zone1][:duration],
      zone2: zones[:zone2][:duration],
      zone3: zones[:zone3][:duration],
      zone4: zones[:zone4][:duration]
    }
  end
end