require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

Dotenv.load

require './config/environments.rb'
require './models/user.rb'
require './models/stop.rb'
require './behaviors/GetBusTimes.rb'
require './behaviors/HandleIntentRequest.rb'

["lib", "models", "behaviors", "config"].each do |dir|
  Dir.glob(File.expand_path("./#{dir}/*.rb")).each {|file| require file }
end

DOMAIN = "https://quiet-headland-17584.herokuapp.com"

before '/alexa_endpoint' do
  content_type('application/json')
end

post '/alexa_endpoint' do
  request_json = JSON.parse(request.body.read.to_s)
  request = AlexaRubykit.build_request(request_json)

  amazon_device_id = request.session.user["userId"]
  alexa = Alexa.find_by(alexa_user_id: amazon_device_id) || Alexa.create(alexa_user_id: amazon_device_id)
  user = alexa.user

  response = AlexaRubykit::Response.new

  if user.nil? && alexa.activation_key
    response.add_speech("Please activate your device at #{DOMAIN}. Create an account and then enter your unique activation code. Your code is <say-as interpret-as='spell-out'>#{alexa.activation_key}</say-as>")
  elsif user.nil?
    token = rand(36**8).to_s(36)
    alexa.update(activation_key: token)
    response.add_speech("Please activate your device at #{DOMAIN}. Create an account and then enter your unique activation code. Your code is <say-as interpret-as='spell-out'>#{alexa.activation_key}</say-as>")
  else
    handle_request(request, user, response)
  end

  response.build_response
end

def handle_request(request, user, response)
  time = Time.now
  time_string = "The time is now #{time.strftime("%l:%M%p")}. "

  p "Request Type: #{request.type}"
  case request.type
  when 'LAUNCH_REQUEST'
    default_stop = get_default_stop(user)
    if default_stop
      bus_string = GetBusTimes.perform(stop_id: default_stop.mta_stop_id, time_to_stop: 360)
      response.add_speech("It's lit. " + time_string + bus_string)
      response.add_hash_card( { :title => 'Nextbus Running', :subtitle => 'It is truly lit' } )
    else
      response.add_speech("Error: there are no bus stops tied to this account yet")
      response.add_hash_card( { :title => 'Error', :subtitle => 'there are no bus stops tied to this account yet' } )
    end
  when 'INTENT_REQUEST'
    p request
    p "request slots: #{request.slots}"
    response_string = HandleIntentRequest.perform(user: user, request: request, response: response)
    response.add_speech(response_string)
    response.add_hash_card( { :title => 'Ruby Intent', :subtitle => "Intent #{request.name}" } )
  when 'SESSION_ENDED_REQUEST'
    p "request reason: #{request.reason}"
    halt 200
  else
    p "INVALID REQUEST TYPE"
  end
end

def get_default_stop(user)
  user.stops.where(default: true).first || user.stops.first
end

enable :sessions

def check_logged_in
  redirect to('/signup') unless logged_in?
end

def check_logged_out
  redirect to('/home') if logged_in?
end

def logged_in?
  true if session[:user_id]
end

get '/' do
  check_logged_in
  redirect to('/home')
end

get '/signup' do
  check_logged_out
  haml :signup
end

post '/signup' do
  check_logged_out
  user = User.new(email: params[:email], password: params[:pw1], password_confirmation: params[:pw2])
  if user.save
    session[:user_id] = user.id
    redirect to('/activate')
  else
    haml :signup, locals: {email: user.email, signup_errors: user.errors.full_messages}
  end
end

get '/activate' do
  check_logged_in
  activate_errors = session[:activate_errors]
  session.delete(:activate_errors)
  haml :activate, locals: {activate_errors: activate_errors}
end

post '/activate' do
  check_logged_in
  alexa = Alexa.find_by(activation_key: params[:activationcode])
  if alexa && alexa.user_id.nil?
    alexa.update(user_id: session[:user_id])
    redirect to('/home')
  elsif alexa && alexa.user_id == session[:user_id]
    session[:activate_errors] = ["This device is already tied to your account"]
    redirect back
  elsif alexa
    session[:activate_errors] = ["This device is already tied to a different account"]
    redirect back
  else
    session[:activate_errors] = ["Code not found. Ask alexa for a new code."]
    redirect back
  end
end

get '/login' do
  check_logged_out
  haml :login
end

post '/login' do
  check_logged_out
  user = User.find_by(email: params[:email])
  if user && user.authenticate(params[:pw])
    session[:user_id] = user.id
    redirect to('/home')
  else
    haml :login, locals: {errors: ["Error: invalid login credentials"]}
  end
end

get '/logout' do
  session.clear
  redirect to('/login')
end

get '/home' do
  check_logged_in
  user = User.find(session[:user_id])

  #get error messages about activating alexa device
  #and clear them from the session
  activate_errors = session[:activate_errors]
  session.delete(:activate_errors)

  #get error messages about adding a new stop
  #and clear them from the session
  add_stop_errors = session[:add_stop_errors]
  session.delete(:add_stop_errors)

  #get default stop id
  default_stop = get_default_stop(user)
  default_stop_id = default_stop.id if default_stop

  haml :loggedin, locals: {email: user.email, devices: user.alexas, stops: user.stops, default_stop_id: default_stop_id, activate_errors: activate_errors, add_stop_errors: add_stop_errors}
end

get '/addstop' do
  check_logged_in
  add_stop_errors = session[:add_stop_errors]
  session.delete(:add_stop_errors)
  haml :addstop, locals: {add_stop_errors: add_stop_errors}
end

post '/addstop' do
  check_logged_in
  stop = Stop.new(name: params[:stop_name], mta_stop_id: params[:mta_stop_id], user_id: session[:user_id])
  mta_record = GTFS::ORM::Stop.where(stop_id: stop.mta_stop_id.to_s).first
  if mta_record && stop.save
    stop.make_default if params[:default_stop]
    redirect to('/home')
  elsif mta_record
    session[:add_stop_errors] = stop.errors.full_messages
    redirect back
  else
    session[:add_stop_errors] = stop.errors.full_messages
    session[:add_stop_errors] << "Stop ID does not exist"
    redirect back
  end
end

delete '/stops/:id' do |id|
  check_logged_in
  if s = Stop.find(id)
    s.destroy
  end
  redirect back
end

post '/stops/:id' do |id|
  check_logged_in
  stop = Stop.find(id)
  if stop && params[:default]
    stop.make_default
  end
  redirect back
end

delete '/devices/:id' do |id|
  check_logged_in
  if d = Alexa.find(id)
    d.destroy
  end
  redirect back
end
