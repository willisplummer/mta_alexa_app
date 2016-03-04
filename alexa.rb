require 'sinatra'
require 'json'
require 'bundler/setup'
require 'alexa_rubykit'

before do
  content_type('application/json')
end

post '/' do
  request_json = JSON.parse(request.body.read.to_s)
  request = AlexaRubykit.build_request(request_json)
response = AlexRubykit::Response.new
response.add_speech('Ruby is running')
response.build_response
