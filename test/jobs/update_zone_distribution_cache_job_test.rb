require "test_helper"

class UpdateZoneDistributionCacheJobTest < ActiveJob::TestCase
  fixtures :all

  setup do
    # Ensure we're using a memory cache store for tests
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "job updates cache with zone distribution data" do
    # Clear any existing cache
    Rails.cache.clear

    # Perform the job
    UpdateZoneDistributionCacheJob.perform_now

    # Verify cache was written
    cached_result = Rails.cache.read("heart_rate_zone_percentage_distribution")
    assert_not_nil cached_result

    # Verify it has the correct structure
    assert_equal 87.5, cached_result[:"Zone 1"]
    assert_equal 0.0, cached_result[:"Zone 2"]
    assert_equal 0.0, cached_result[:"Zone 3"]
    assert_equal 0.0, cached_result[:"Zone 4"]
    assert_equal 12.5, cached_result[:"Out of Zone"]
  end

  test "job returns the calculated result" do
    result = UpdateZoneDistributionCacheJob.perform_now

    assert_equal 87.5, result[:"Zone 1"]
    assert_equal 12.5, result[:"Out of Zone"]
  end

  test "job can be enqueued" do
    assert_enqueued_with(job: UpdateZoneDistributionCacheJob) do
      UpdateZoneDistributionCacheJob.perform_later
    end
  end

  test "job handles empty database" do
    HeartRate.destroy_all

    result = UpdateZoneDistributionCacheJob.perform_now

    assert_equal({}, result)
    assert_equal({}, Rails.cache.read("heart_rate_zone_percentage_distribution"))
  end

  test "job stores timestamp when cache is updated" do
    Rails.cache.clear

    # Perform the job
    before_time = Time.current
    UpdateZoneDistributionCacheJob.perform_now
    after_time = Time.current

    # Verify timestamp was written
    cached_timestamp = Rails.cache.read("heart_rate_zone_percentage_distribution_updated_at")
    assert_not_nil cached_timestamp

    # Verify timestamp is within expected range
    assert cached_timestamp >= before_time
    assert cached_timestamp <= after_time
  end
end
