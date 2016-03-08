require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

Dotenv.load


require './config/environments.rb'
require './models/user.rb'
require './behaviors/GetBusTimes.rb'
require './behaviors/HandleIntentRequest.rb'

before do
  content_type('application/json')
end

get '/' do
  "alexa mta app"
end

post '/' do
  # Check that it's a valid Alexa request
  request_json = JSON.parse(request.body.read.to_s)
  # Creates a new Request object with the request parameter.
  request = AlexaRubykit.build_request(request_json)

  # We can capture Session details inside of request.
  # See session object for more information.
  session = request.session
  p session.new?
  p session.has_attributes?
  p session.session_id
  p session.user_defined?
  p session.user
  uid = session.user["userId"]
  p uid
  user = User.find_by(alexa_user_id: uid) || User.create(alexa_user_id: uid)
  p user.id
  p user.stops
  # We need a response object to respond to the Alexa.
  response = AlexaRubykit::Response.new

  time = Time.now
  time_string = "The time is now #{time.strftime("%l:%M%p")}. "

  if (request.type == 'LAUNCH_REQUEST')
    # Process your Launch Request
    # Call your methods for your application here that process your Launch Request.
    bus_string = GetBusTimes.perform(stop_id: "901280", time_to_stop: 360)
    response.add_speech("It's lit. " + time_string + bus_string)
    response.add_hash_card( { :title => 'Nextbus Running', :subtitle => 'It is truly lit' } )
  end

  if (request.type == 'INTENT_REQUEST')
    # Process your Intent Request
    p request.slots
    response_string = HandleIntentRequest.perform(request)
    response.add_speech(time_string + response_string)
    response.add_hash_card( { :title => 'Ruby Intent', :subtitle => "Intent #{request.name}" } )
  end

  if (request.type =='SESSION_ENDED_REQUEST')
    # Wrap up whatever we need to do.
    p "#{request.type}"
    p "#{request.reason}"
    halt 200
  end

  # Return response
  response.build_response
end
