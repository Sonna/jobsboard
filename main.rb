     
require 'sinatra'
# require 'sinatra/reloader'
require 'sinatra/flash'
require 'httparty'
require_relative 'db_config'
require_relative 'models/job'
require_relative 'models/user'
require_relative 'models/favourite_job'

helpers do
  
  def job_search_result search_term, page
    url = "https://chalice-search-experience-api.cloud.seek.com.au/search?where=All+Australia&page=#{page}&seekSelectAllPages=true&keywords=#{search_term}&classification=6281&isDesktop=true"
    HTTParty.get(url)
  end
  
  def alreay_in_db jobid
    !Job.find_by(jobid: jobid)
  end

  def save_search_job_in_DB jobs
    jobs.each do |result_job|
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
  end

  def alreay_sign_in email
    User.find_by(email: email)
  end

  def current_user
    User.find_by(id: session[:user_id])
  end

  def logged_in?
   current_user ? true : false
  end

  def job_saved? jobid
    FavouriteJob.where(user_id: session[:user_id], job_id:jobid).any?
  end

  def get_integer_job_id long_job_id
    Job.find_by(jobid:long_job_id)['id']
  end

  def get_job_status job_id
    FavouriteJob.find_by(job_id: job_id)['status']
  end

  def get_job_comment job_id
    !!FavouriteJob.find_by(job_id: job_id)['comment']
  end

end

enable :sessions

get '/' do
  @jobs = Job.where(location: 'Melbourne')
  erb :index
end

get '/jobs' do
  @jobs = (job_search_result params[:keyword],params[:page]).parsed_response['data']
  save_search_job_in_DB @jobs

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
  user = alreay_sign_in params[:email]
  if user
    if user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect '/users/dashboard'
    else 
      flash[:notice] = "Incorrect Password!"
      redirect '/users/login'
    end
  else
    flash[:notice] = "You have not sign up yet, please sign up first!"
    redirect '/users/sign_up'
  end
end


delete '/users/logout_session' do
  session[:user_id] = nil
  redirect '/'
end

post '/users/save_jobs' do
  favourite_jobs = FavouriteJob.new
  favourite_jobs.user_id = session[:user_id]
  favourite_jobs.job_id = params[:save_job]
  favourite_jobs.status = "not apply"
  favourite_jobs.save
  redirect back
end

delete '/users/unsave_jobs/:jobid' do
  FavouriteJob.where(user_id: session[:user_id], job_id: params[:jobid]).destroy_all
  redirect back
end

get '/users/dashboard' do 
  if !logged_in?
    redirect '/users/login'
  else
    @user_saved_jobs = User.find_by(id: session[:user_id]).jobs
    erb :dashboard
  end
end

get '/users/saved_jobs/edit/:id' do
  @edit_progress_job = Job.find_by(id: params[:id])
  @favourite_job = @edit_progress_job.favourite_jobs.first
  erb :edit
end

put '/users/update_status/:id' do
  favourite_job = FavouriteJob.find_by(job_id: params[:id])
  favourite_job.status = params[:status]
  favourite_job.comment = params[:comment]
  favourite_job.save
  redirect '/users/dashboard'
end

