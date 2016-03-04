require 'sinatra'
require 'json'
require 'bundler/setup'
require 'alexa_rubykit'

# before do
#   content_type('application/json')
# end

get '/' do
  "hello world"
end
