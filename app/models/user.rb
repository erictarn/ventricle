class User < ApplicationRecord
  has_many :monitoring_sessions
end