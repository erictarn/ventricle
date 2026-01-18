require "test_helper"

class MonitoringSessionTest < ActiveSupport::TestCase
  fixtures :all

  # Association tests
  test "belongs to user" do
    session = monitoring_sessions(:session_one)
    assert_instance_of User, session.user
    assert_equal users(:john), session.user
  end

  test "has many heart rates" do
    session = monitoring_sessions(:session_one)
    assert_respond_to session, :heart_rates
    assert_equal 4, session.heart_rates.count
  end

  test "destroys associated heart rates when session is destroyed" do
    session = monitoring_sessions(:session_one)
    heart_rate_ids = session.heart_rates.pluck(:id)

    assert_difference "HeartRate.count", -4 do
      session.destroy
    end

    heart_rate_ids.each do |id|
      assert_nil HeartRate.find_by(id: id)
    end
  end

  # min_hr tests
  test "min_hr returns the lowest BPM when multiple heart rates exist" do
    session = monitoring_sessions(:session_one)
    # Session one has: 62, 75, 88, 70
    assert_equal 62, session.min_hr
  end

  test "min_hr only considers heart rates for the specific session" do
    session_one = monitoring_sessions(:session_one)
    session_two = monitoring_sessions(:session_two)

    assert_equal 62, session_one.min_hr
    assert_equal 50, session_two.min_hr
  end

  test "min_hr returns nil when no heart rates exist" do
    session = monitoring_sessions(:empty_session)

    assert_nil session.min_hr
  end

  test "min_hr handles duplicate minimum values correctly" do
    session = monitoring_sessions(:session_two)

    # Session two has: 50, 60, 60, 90
    assert_equal 50, session.min_hr
  end

  # max_hr tests
  test "max_hr returns the highest BPM when multiple heart rates exist" do
    session = monitoring_sessions(:session_one)
    # Session one has: 62, 75, 88, 70
    assert_equal 88, session.max_hr
  end

  test "max_hr only considers heart rates for the specific session" do
    session_one = monitoring_sessions(:session_one)
    session_two = monitoring_sessions(:session_two)

    assert_equal 88, session_one.max_hr
    assert_equal 90, session_two.max_hr
  end

  test "max_hr returns nil when no heart rates exist" do
    session = monitoring_sessions(:empty_session)

    assert_nil session.max_hr
  end

  test "max_hr handles duplicate maximum values correctly" do
    session = monitoring_sessions(:session_two)

    # Session two has: 50, 60, 60, 90
    assert_equal 90, session.max_hr
  end

  # avg_hr tests
  test "avg_hr returns the average BPM when multiple heart rates exist" do
    session = monitoring_sessions(:session_one)
    # Session one has: 62, 75, 88, 70
    # Average: (62 + 75 + 88 + 70) / 4 = 295 / 4 = 73.75
    assert_equal 73.75, session.avg_hr
  end

  test "avg_hr only considers heart rates for the specific session" do
    session_one = monitoring_sessions(:session_one)
    session_two = monitoring_sessions(:session_two)

    # Session one: (62 + 75 + 88 + 70) / 4 = 73.75
    assert_equal 73.75, session_one.avg_hr

    # Session two: (50 + 60 + 60 + 90) / 4 = 65.0
    assert_equal 65.0, session_two.avg_hr
  end

  test "avg_hr returns nil when no heart rates exist" do
    session = monitoring_sessions(:empty_session)

    assert_nil session.avg_hr
  end

  test "avg_hr handles integer values correctly" do
    session = monitoring_sessions(:session_two)

    # Session two has: 50, 60, 60, 90
    # Average: (50 + 60 + 60 + 90) / 4 = 260 / 4 = 65.0
    assert_equal 65.0, session.avg_hr
  end

  # zone_durations tests
  test "zone_durations calculates time in each zone correctly" do
    session = monitoring_sessions(:session_one)
    # John's zones: zone1(50-100), zone2(100-120), zone3(120-140), zone4(140-160)
    # Session one heart rates: 62, 75, 88, 70 - all in zone1, each 300 seconds
    result = session.zone_durations

    assert_equal 1200, result[:zone1]  # All 4 heart rates * 300 seconds
    assert_equal 0, result[:zone2]
    assert_equal 0, result[:zone3]
    assert_equal 0, result[:zone4]
  end

  test "zone_durations handles heart rates across multiple zones" do
    # Create a session with heart rates in different zones
    session = monitoring_sessions(:session_one)
    # Add heart rates in different zones for testing
    session.heart_rates.create!(bpm: 105, duration_in_secs: 600, start_time: Time.now, end_time: Time.now + 10.minutes)  # zone2
    session.heart_rates.create!(bpm: 125, duration_in_secs: 400, start_time: Time.now, end_time: Time.now + 6.minutes)   # zone3
    session.heart_rates.create!(bpm: 145, duration_in_secs: 200, start_time: Time.now, end_time: Time.now + 3.minutes)   # zone4

    result = session.zone_durations

    assert_equal 1200, result[:zone1]  # Original 4 heart rates
    assert_equal 600, result[:zone2]
    assert_equal 400, result[:zone3]
    assert_equal 200, result[:zone4]
  end

  test "zone_durations returns zeros for empty session" do
    session = monitoring_sessions(:empty_session)

    result = session.zone_durations

    assert_equal 0, result[:zone1]
    assert_equal 0, result[:zone2]
    assert_equal 0, result[:zone3]
    assert_equal 0, result[:zone4]
  end

  test "zone_durations excludes heart rates outside all zones" do
    session = monitoring_sessions(:session_two)
    # Jane's zones: zone1(55-95), zone2(95-115), zone3(115-135), zone4(135-155)
    # Session two has: 50 (below all zones), 90, 60, 60 (all in zone1)
    result = session.zone_durations

    # Only 90, 60, 60 are in zone1 (each 300 seconds)
    assert_equal 900, result[:zone1]
    assert_equal 0, result[:zone2]
    assert_equal 0, result[:zone3]
    assert_equal 0, result[:zone4]
  end

  test "zone_durations handles nil bpm and duration values" do
    session = monitoring_sessions(:session_one)
    session.heart_rates.create!(bpm: nil, duration_in_secs: 300)
    session.heart_rates.create!(bpm: 75, duration_in_secs: nil)

    result = session.zone_durations

    # Should still calculate correctly for valid heart rates (original 4)
    assert_equal 1200, result[:zone1]
  end

  test "zone_durations returns empty hash when user is nil" do
    session = MonitoringSession.new
    result = session.zone_durations

    assert_equal({}, result)
  end
end