require 'rubygems'
require 'bundler/setup'
require 'dotenv'
require 'sinatra'
Dotenv.load

require './api.rb'


before do
  content_type('application/json')
end

get '/' do
  GetBusTimes.perform(stop_id: "901280")
end

post '/' do
  "test"
end
