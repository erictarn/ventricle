require "test_helper"

class HeartRateTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  fixtures :all

  setup do
    # Ensure we're using a memory cache store for tests
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  # Association tests
  test "belongs to monitoring session" do
    heart_rate = heart_rates(:session_one_low)
    assert_instance_of MonitoringSession, heart_rate.monitoring_session
    assert_equal monitoring_sessions(:session_one), heart_rate.monitoring_session
  end

  # min_bpm class method tests
  test "min_bpm returns the lowest BPM across all heart rates" do
    # From fixtures: session_one has 62, 75, 88, 70
    #                session_two has 50, 90, 60, 60
    # Global minimum should be 50
    assert_equal 50, HeartRate.min_bpm
  end

  test "min_bpm returns nil when no heart rates exist" do
    HeartRate.destroy_all
    assert_nil HeartRate.min_bpm
  end

  test "min_bpm handles duplicate minimum values" do
    # Even if multiple heart rates have the same minimum value, should still return that value
    assert_equal 50, HeartRate.min_bpm

    # Verify there are heart rates with BPM of 50
    assert HeartRate.exists?(bpm: 50)
  end

  test "min_bpm ignores nil bpm values" do
    # Create a heart rate with nil bpm
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: nil, duration_in_secs: 300)

    # Should still return 50, not nil
    assert_equal 50, HeartRate.min_bpm
  end

  # max_bpm class method tests
  test "max_bpm returns the highest BPM across all heart rates" do
    # From fixtures: session_one has 62, 75, 88, 70
    #                session_two has 50, 90, 60, 60
    # Global maximum should be 90
    assert_equal 90, HeartRate.max_bpm
  end

  test "max_bpm returns nil when no heart rates exist" do
    HeartRate.destroy_all
    assert_nil HeartRate.max_bpm
  end

  test "max_bpm handles duplicate maximum values" do
    # Create another heart rate with BPM of 90
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 90, duration_in_secs: 300)

    # Should still return 90
    assert_equal 90, HeartRate.max_bpm

    # Verify there are multiple heart rates with BPM of 90
    assert_equal 2, HeartRate.where(bpm: 90).count
  end

  test "max_bpm ignores nil bpm values" do
    # Create a heart rate with nil bpm
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: nil, duration_in_secs: 300)

    # Should still return 90, not nil
    assert_equal 90, HeartRate.max_bpm
  end

  # avg_bpm class method tests
  test "avg_bpm returns the average BPM across all heart rates" do
    # From fixtures: session_one has 62, 75, 88, 70
    #                session_two has 50, 90, 60, 60
    # Global average: (62 + 75 + 88 + 70 + 50 + 90 + 60 + 60) / 8 = 555 / 8 = 69.375
    assert_equal 69.375, HeartRate.avg_bpm
  end

  test "avg_bpm returns nil when no heart rates exist" do
    HeartRate.destroy_all
    assert_nil HeartRate.avg_bpm
  end

  test "avg_bpm ignores nil bpm values" do
    # Create a heart rate with nil bpm
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: nil, duration_in_secs: 300)

    # Should still calculate average from non-nil values
    # (62 + 75 + 88 + 70 + 50 + 90 + 60 + 60) / 8 = 69.375
    assert_equal 69.375, HeartRate.avg_bpm
  end

  test "avg_bpm handles integer division correctly" do
    HeartRate.destroy_all
    # Create heart rates that would result in a decimal average
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 100, duration_in_secs: 300)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 101, duration_in_secs: 300)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 102, duration_in_secs: 300)

    # Average: (100 + 101 + 102) / 3 = 303 / 3 = 101.0
    assert_equal 101.0, HeartRate.avg_bpm
  end

  # zone_percentage_distribution class method tests
  test "zone_percentage_distribution calculates percentages across all users" do
    # From fixtures:
    # session_one (john: zone1=50-100, zone2=100-120, zone3=120-140, zone4=140-160):
    #   62, 75, 88, 70 - all in zone1 = 4 * 300 = 1200 seconds
    # session_two (jane: zone1=55-95, zone2=95-115, zone3=115-135, zone4=135-155):
    #   50 (unzoned, below 55), 90, 60, 60 - 3 in zone1 = 3 * 300 = 900 seconds, 1 unzoned = 300 seconds
    # Total: zone1=2100, unzoned=300, total=2400
    # Percentages: zone1=87.5%, zone2=0%, zone3=0%, zone4=0%, unzoned=12.5%

    result = HeartRate.zone_percentage_distribution

    assert_equal 87.5, result[:zone1]
    assert_equal 0.0, result[:zone2]
    assert_equal 0.0, result[:zone3]
    assert_equal 0.0, result[:zone4]
    assert_equal 12.5, result[:unzoned]
  end

  test "zone_percentage_distribution percentages sum to 100" do
    result = HeartRate.zone_percentage_distribution
    total = result[:zone1] + result[:zone2] + result[:zone3] + result[:zone4] + result[:unzoned]

    assert_equal 100.0, total
  end

  test "zone_percentage_distribution returns empty hash when no heart rates exist" do
    HeartRate.destroy_all
    result = HeartRate.zone_percentage_distribution

    assert_equal({}, result)
  end

  test "zone_percentage_distribution handles heart rates across multiple zones" do
    HeartRate.destroy_all

    # Create heart rates in different zones
    # John's zones: zone1(50-100), zone2(100-120), zone3(120-140), zone4(140-160)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 75, duration_in_secs: 1000)  # zone1
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 110, duration_in_secs: 1000) # zone2
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 130, duration_in_secs: 1000) # zone3
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 150, duration_in_secs: 1000) # zone4

    # Total: 4000 seconds, 1000 in each zone
    result = HeartRate.zone_percentage_distribution

    assert_equal 25.0, result[:zone1]
    assert_equal 25.0, result[:zone2]
    assert_equal 25.0, result[:zone3]
    assert_equal 25.0, result[:zone4]
    assert_equal 0.0, result[:unzoned]
  end

  test "zone_percentage_distribution ignores nil bpm and duration values" do
    # Add heart rates with nil values
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: nil, duration_in_secs: 300)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 75, duration_in_secs: nil)

    # Should still calculate based on valid heart rates (same as first test)
    result = HeartRate.zone_percentage_distribution

    assert_equal 87.5, result[:zone1]
    assert_equal 12.5, result[:unzoned]
  end

  test "zone_percentage_distribution handles different users with different zones" do
    HeartRate.destroy_all

    # John's zones: zone1(50-100), zone2(100-120), zone3(120-140), zone4(140-160)
    # Create 1000 seconds in john's zone1 (bpm=75)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 75, duration_in_secs: 1000)

    # Jane's zones: zone1(55-95), zone2(95-115), zone3(115-135), zone4(135-155)
    # Create 1000 seconds in jane's zone2 (bpm=100)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_two), bpm: 100, duration_in_secs: 1000)

    # Total: 2000 seconds, 1000 in zone1, 1000 in zone2
    result = HeartRate.zone_percentage_distribution

    assert_equal 50.0, result[:zone1]
    assert_equal 50.0, result[:zone2]
    assert_equal 0.0, result[:zone3]
    assert_equal 0.0, result[:zone4]
    assert_equal 0.0, result[:unzoned]
  end

  test "zone_percentage_distribution rounds to 2 decimal places" do
    HeartRate.destroy_all

    # Create durations that will result in repeating decimals
    # 1000 seconds in zone1, 2000 seconds in zone2 = 3000 total
    # zone1 = 1000/3000 = 33.333...%
    # zone2 = 2000/3000 = 66.666...%
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 75, duration_in_secs: 1000)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 110, duration_in_secs: 2000)

    result = HeartRate.zone_percentage_distribution

    assert_equal 33.33, result[:zone1]
    assert_equal 66.67, result[:zone2]
  end

  # zone_percentage_distribution_sql class method tests (SQL-optimized version)
  test "zone_percentage_distribution_sql calculates percentages across all users" do
    # Same test as zone_percentage_distribution but using SQL version
    result = HeartRate.zone_percentage_distribution_sql

    assert_equal 87.5, result[:"Zone 1"]
    assert_equal 0.0, result[:"Zone 2"]
    assert_equal 0.0, result[:"Zone 3"]
    assert_equal 0.0, result[:"Zone 4"]
    assert_equal 12.5, result[:"Out of Zone"]
  end

  test "zone_percentage_distribution_sql returns same results as Ruby version" do
    # Verify both methods produce identical results
    ruby_result = HeartRate.zone_percentage_distribution
    sql_result = HeartRate.zone_percentage_distribution_sql

    # Convert Ruby result keys to match SQL result format
    expected = {
      "Zone 1": ruby_result[:zone1],
      "Zone 2": ruby_result[:zone2],
      "Zone 3": ruby_result[:zone3],
      "Zone 4": ruby_result[:zone4],
      "Out of Zone": ruby_result[:unzoned]
    }

    assert_equal expected, sql_result
  end

  test "zone_percentage_distribution_sql returns empty hash when no heart rates exist" do
    HeartRate.destroy_all
    result = HeartRate.zone_percentage_distribution_sql

    assert_equal({}, result)
  end

  test "zone_percentage_distribution_sql handles heart rates across multiple zones" do
    HeartRate.destroy_all

    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 75, duration_in_secs: 1000)  # zone1
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 110, duration_in_secs: 1000) # zone2
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 130, duration_in_secs: 1000) # zone3
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 150, duration_in_secs: 1000) # zone4

    result = HeartRate.zone_percentage_distribution_sql

    assert_equal 25.0, result[:"Zone 1"]
    assert_equal 25.0, result[:"Zone 2"]
    assert_equal 25.0, result[:"Zone 3"]
    assert_equal 25.0, result[:"Zone 4"]
    assert_equal 0.0, result[:"Out of Zone"]
  end

  test "zone_percentage_distribution_sql ignores nil bpm and duration values" do
    # Add heart rates with nil values
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: nil, duration_in_secs: 300)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 75, duration_in_secs: nil)

    result = HeartRate.zone_percentage_distribution_sql

    assert_equal 87.5, result[:"Zone 1"]
    assert_equal 12.5, result[:"Out of Zone"]
  end

  test "zone_percentage_distribution_sql handles different users with different zones" do
    HeartRate.destroy_all

    HeartRate.create!(monitoring_session: monitoring_sessions(:session_one), bpm: 75, duration_in_secs: 1000)
    HeartRate.create!(monitoring_session: monitoring_sessions(:session_two), bpm: 100, duration_in_secs: 1000)

    result = HeartRate.zone_percentage_distribution_sql

    assert_equal 50.0, result[:"Zone 1"]
    assert_equal 50.0, result[:"Zone 2"]
    assert_equal 0.0, result[:"Zone 3"]
    assert_equal 0.0, result[:"Zone 4"]
    assert_equal 0.0, result[:"Out of Zone"]
  end

  # zone_percentage_distribution_cached tests
  test "zone_percentage_distribution_cached returns cached value when cache exists" do
    # Pre-populate cache
    expected_result = { zone1: 10.0, zone2: 20.0, zone3: 30.0, zone4: 25.0, unzoned: 15.0 }
    Rails.cache.write("heart_rate_zone_percentage_distribution", expected_result)

    result = HeartRate.zone_percentage_distribution_cached

    assert_equal expected_result, result
  end

  test "zone_percentage_distribution_cached enqueues job and returns empty hash when cache is empty" do
    Rails.cache.clear

    assert_enqueued_with(job: UpdateZoneDistributionCacheJob) do
      result = HeartRate.zone_percentage_distribution_cached
      assert_equal({}, result)
    end
  end

  test "refresh_zone_distribution_cache enqueues background job" do
    assert_enqueued_with(job: UpdateZoneDistributionCacheJob) do
      HeartRate.refresh_zone_distribution_cache
    end
  end

  test "zone_distribution_last_updated returns timestamp when cache exists" do
    # Set a timestamp in cache
    timestamp = Time.current
    Rails.cache.write("heart_rate_zone_percentage_distribution_updated_at", timestamp)

    result = HeartRate.zone_distribution_last_updated

    assert_equal timestamp, result
  end

  test "zone_distribution_last_updated returns nil when cache is empty" do
    Rails.cache.clear

    result = HeartRate.zone_distribution_last_updated

    assert_nil result
  end
end
