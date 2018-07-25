class User < ActiveRecord::Base
  has_secure_password
  has_many :favourite_jobs
end