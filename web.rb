require 'sinatra'
require 'json'
require 'bundler/setup'
require 'alexa_rubykit'
require 'api.rb'

before do
  content_type('application/json')
end

get '/' do
  GetBusTimes.perform(stop_id: "901280")
end

post '/' do
  "test"
end
