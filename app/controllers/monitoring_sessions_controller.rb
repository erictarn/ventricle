class MonitoringSessionsController < ApplicationController
  def index
    @monitoring_sessions = MonitoringSession.all.limit(50)
  end
end