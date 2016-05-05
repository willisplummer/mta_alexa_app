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

enable :sessions

get '/' do
  "alexa mta app"
end

get '/signup' do
  haml :signup
end

post '/signup' do
  email = params[:email]
  pw1 = params[:pw1]
  pw2 = params[:pw2]
  user = User.new(email: email, password: pw1)
  if user.save
    session[:user] = user
    redirect to('/activate')
  else
    haml :signup, locals: {email: email, pw1: pw1, pw2: pw2, errors: user}
  end
end

get '/activate' do
  if session[:user]
    haml :activate
  else
    redirect to('/signup')
  end
end

post '/activate' do
  if session[:user]
    alexa = Alexa.find_by(activation_key: params[:activationcode])
    if alexa && alexa.user_id.nil?
      alexa.update(user_id: session[:user].id)
      "connected"
    elsif alexa && alexa.user_id == session[:user].id
      haml :activate, locals: {errors: ["This device is already tied to your account"]}
    elsif alexa
      haml :activate, locals: {errors: ["This device is already tied to a different account"]}
    else
      haml :activate, locals: {errors: ["Code not found. Ask alexa for a new code."]}
    end
  else
    redirect to('/signup')
  end
end

before '/' do
  content_type('application/json')
end

post '/' do
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
