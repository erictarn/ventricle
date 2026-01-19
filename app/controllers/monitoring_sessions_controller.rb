class MonitoringSessionsController < ApplicationController
  def index
    @monitoring_sessions = MonitoringSession.includes(:user)

    # Get date range for the date picker
    @min_date = MonitoringSession.minimum(:created_at)&.to_date
    @max_date = MonitoringSession.maximum(:created_at)&.to_date

    if params[:search].present?
      @monitoring_sessions = @monitoring_sessions.joins(:user).where("users.username LIKE ?", "%#{params[:search]}%").limit(500)
    end

    if params[:date].present?
      date = Date.parse(params[:date])
      start_time = date.to_time.utc.beginning_of_day
      end_time = date.to_time.utc.end_of_day
      @monitoring_sessions = @monitoring_sessions.where(created_at: start_time..end_time)
    end

    if params[:search].blank? && params[:date].blank?
      @monitoring_sessions = @monitoring_sessions.order(created_at: :desc).limit(10)
    else
      @monitoring_sessions = @monitoring_sessions.order(created_at: :desc)
    end
  end

  def show
    @monitoring_session = MonitoringSession.includes(:user, :heart_rates).find(params[:id])
  end

  def refresh_zone_distribution
    # Run the job synchronously to update the cache
    result = HeartRate.zone_percentage_distribution_sql
    Rails.cache.write("heart_rate_zone_percentage_distribution", result, expires_in: 1.hour)
    Rails.cache.write("heart_rate_zone_percentage_distribution_updated_at", Time.current, expires_in: 1.hour)

    render json: {
      data: result,
      updated_at: Time.current.iso8601
    }
  end
end