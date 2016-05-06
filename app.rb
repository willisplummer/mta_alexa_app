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

before '/' do
  content_type('application/json')
end

post '/' do
  request_json = JSON.parse(request.body.read.to_s)
  request = AlexaRubykit.build_request(request_json)

  response = AlexaRubykit::Response.new

  session = request.session
  amazon_device_id = session.user["userId"]
  alexa = Alexa.find_by(alexa_user_id: amazon_device_id) || Alexa.create(alexa_user_id: amazon_device_id)
  user = alexa.user

  if user.nil? && alexa.activation_key
    response.add_speech("Please activate your device at #{DOMAIN}. Create an account and then enter your unique activation code. Your code is <say-as interpret-as='spell-out'>#{alexa.activation_key}</say-as>")
  elsif user.nil?
    token = rand(36**8).to_s(36)
    alexa.update(activation_key: token)
    response.add_speech("Please activate your device at #{DOMAIN}. Create an account and then enter your unique activation code. Your code is <say-as interpret-as='spell-out'>#{alexa.activation_key}</say-as>")
  else
    response.add_speech("you are hooked up")
  end

  response.build_response
end

enable :sessions

def check_logged_in
  redirect to('/signup') unless session[:user_id]
end

def check_logged_out
  redirect to('/home') if session[:user_id]
end

get '/' do
  redirect to('/signup')
end

get '/signup' do
  check_logged_out
  haml :signup
end

post '/signup' do
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

  haml :loggedin, locals: {email: user.email, devices: user.alexas, stops: user.stops, activate_errors: activate_errors, add_stop_errors: add_stop_errors}
end

get '/addstop' do
  check_logged_in
  add_stop_errors = session[:add_stop_errors]
  session.delete(:add_stop_errors)
  haml :addstop, locals: {add_stop_errors: add_stop_errors}
end

post '/addstop' do
  stop = Stop.new(name: params[:stop_name], mta_stop_id: params[:mta_stop_id], user_id: session[:user_id])
  if stop.save
    redirect to('/home')
  else
    session[:add_stop_errors] = stop.errors.full_messages
    redirect back
  end
end

#TODO: re-add all this shit about request type handling as a behavior
post '/testtesttest' do
  # Check that it's a valid Alexa request
  request_json = JSON.parse(request.body.read.to_s)

  # Creates a new Request object with the request parameter.
  request = AlexaRubykit.build_request(request_json)

  # We can capture Session details inside of request.
  # See session object for more information.
  session = request.session
  amazon_device_id = session.user["userId"]

  p "amazon user id: #{amazon_device_id}"
  alexa = Alexa.find_by(alexa_user_id: amazon_device_id) || Alexa.create(alexa_user_id: amazon_device_id)
  user_id = alexa.user_id

  # We need a response object to respond to the Alexa.
  response = AlexaRubykit::Response.new

  if !user_id.nil?
    user = User.find(user_id)
    p "user id: #{user.id}"
  elsif alexa.activation_key.nil?
    p "generating activation_key"
    t = rand(36**8).to_s(36)
    alexa.update(activation_key: t)
    p "activation_key: #{t}"
    response.add_speech("Please activate your device at mtabustimes.com. Create an account and then enter your unique activation code: #{alexa.activation_key}")
  else
    p "activation key already exists"
    p "activation_key: #{alexa.activation_key}"
    response.add_speech("Please activate your device. Create an account and then enter your unique activation code: #{alexa.activation_key}")
    response.add_hash_card( { :title => 'Nextbus Running', :subtitle => 'It is truly lit' } )
    response.build_response
    p response
  end

  time = Time.now
  time_string = "The time is now #{time.strftime("%l:%M%p")}. "

  if (request.type == 'LAUNCH_REQUEST' && !user_id.nil?)
    p "LAUNCH REQUEST"
    # Process your Launch Request
    # Call your methods for your application here that process your Launch Request.
    bus_string = GetBusTimes.perform(stop_id: "901280", time_to_stop: 360)
    response.add_speech("It's lit. " + time_string + bus_string)
    response.add_hash_card( { :title => 'Nextbus Running', :subtitle => 'It is truly lit' } )
  end

  if (request.type == 'INTENT_REQUEST' && !user_id.nil?)
    # Process your Intent Request
    p "INTENT REQUEST"
    p request
    p "request slots: #{request.slots}"
    response_string = HandleIntentRequest.perform(user: user, request: request, response: response)
    response.add_speech(response_string)
    response.add_hash_card( { :title => 'Ruby Intent', :subtitle => "Intent #{request.name}" } )
  end

  if (request.type =='SESSION_ENDED_REQUEST' && !user_id.nil?)
    p "SESSION ENDED REQUEST"
    # Wrap up whatever we need to do.
    p "#{request.type}"
    p "#{request.reason}"
    halt 200
  end

  # p "building response"
  # # Return response
  # response.build_response
  # p "built response"
  # p "response: #{response}"
end
