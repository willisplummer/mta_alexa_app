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

get '/' do
  "alexa mta app"
end

get '/signup' do
  haml :signup
end

post '/signup' do
  field = params[:name]
  "got it. your name is #{field}"
end

post '/' do
  content_type('application/json')

  # Check that it's a valid Alexa request
  request_json = JSON.parse(request.body.read.to_s)
  # Creates a new Request object with the request parameter.
  request = AlexaRubykit.build_request(request_json)

  # We can capture Session details inside of request.
  # See session object for more information.
  session = request.session
  uid = session.user["userId"]
  user = User.find_by(alexa_user_id: uid) || User.create(alexa_user_id: uid)
  p "user id: #{user.id}"

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
    p request
    p "request slots: #{request.slots}"
    response_string = HandleIntentRequest.perform(user: user, request: request, response: response)
    response.add_speech(response_string)
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
