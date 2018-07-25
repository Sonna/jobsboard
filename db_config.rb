require 'active_record'

options = {
  adapter: 'postgresql',
  database: 'jobsboard'
}

ActiveRecord::Base.establish_connection(options)