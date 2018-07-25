     
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'httparty'
require_relative 'db_config'
require_relative 'models/jobs'
require_relative 'models/users'
require 'pry'

helpers do
  
  def job_search_result search_term
    url = "https://chalice-search-experience-api.cloud.seek.com.au/search?where=All+Australia&page=1&seekSelectAllPages=true&keywords=#{search_term}&classification=6281&isDesktop=true"
    HTTParty.get(url)
  end
  
  def alreay_in_db jobid
    !Job.find_by(jobid: jobid)
  end

  def alreay_sign_in email
    !!User.find_by(email: email)
  end

  def current_user
    User.find_by(id: session[:user_id])
  end

  def logged_in?
    if current_user
      true
    else
      false
    end
  end
end

enable :sessions

get '/' do
  @jobs = Job.where(location: 'Melbourne')
  erb :index
end

get '/jobs' do
  @jobs = (job_search_result params[:keyword]).parsed_response['data']
  @jobs.each do |result_job|
    if alreay_in_db result_job['id']
      job = Job.new
      job.jobid = result_job['id']
      job.listingdate = result_job['listingDate']
      job.description = result_job["advertiser"]["description"]
      job.title = result_job['title']
      job.location = result_job['location']
      job.save
    end
  end
    erb :jobs
end

get '/users/sign_up' do
  erb :sign_up
end

post '/users/sign_up_session' do
  if (params[:email] == '') || (alreay_sign_in params[:email])
    flash[:notice] = "Email has alreay registed!"
    redirect '/users/sign_up'
  else
    user = User.new
    user.email = params[:email]
    user.password = params[:password]
    user.save
    session[:user_id] = user.id
    redirect '/'
  end
end

get '/users/login' do
  erb :login
end

post '/users/login_session' do
  user = User.find_by(email: params[:email])
  if user
    if user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect '/'
    else 
      flash[:notice] = "Incorrect Password!"
      redirect '/users/login'
    end
  else
    flash[:notice] = "You have not sign up yet, please sign up first!"
    redirect '/users/sign_up'
  end
end



