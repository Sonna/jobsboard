class User < ActiveRecord::Base
  has_secure_password
  has_many :favourite_jobs
  has_many :jobs, through: :favourite_jobs
end