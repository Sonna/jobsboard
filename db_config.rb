require 'active_record'

options = {
  adapter: 'postgresql',
  database: 'jobsboard'
}

# ActiveRecord::Base.establish_connection(options)
ActiveRecord::Base.establish_connection( ENV['DATABASE_URL'] || options)