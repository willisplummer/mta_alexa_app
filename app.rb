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

get '/elm' do
  File.read(File.join('public', 'index.html'))
end

post '/endpoint.json' do
  content_type :json
  p params
  # request_json = JSON.parse(request.body.read.to_s)
  { token: "TOKEN" }.to_json
end

post '/elm-signup.json' do
  content_type :json
  creds = JSON.parse(params["user"])
  user = User.new(email: creds["email"], password: creds["pw"], password_confirmation: creds["pw2"])
  if user.save
    token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Token.exists?(token_string: random_token)
    end

    if user.tokens.new(token_string: token).save
      { token: token, errors: [] }.to_json
    else
      { token: nil, errors: ["Error: problem generating token"] }.to_json
    end

  else
    p user.errors
    { token: nil, errors: user.errors.full_messages }.to_json
  end
end

post '/elm-login.json' do
  content_type :json
  creds = JSON.parse(params["user"])
  p user = User.find_by(email: creds["email"])
  if user && user.authenticate(creds["password"])
    token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Token.exists?(token_string: random_token)
    end

    if user.tokens.new(token_string: token).save
      { token: token, stops: user.stops }.to_json
    else
      { token: nil, errors: "Error: problem generating token" }.to_json
    end
  else
    { token: nil, errors: "Error: invalid login credentials" }.to_json
  end
end
