class MonitoringSession < ApplicationRecord
  belongs_to :user
  has_many :heart_rates
end