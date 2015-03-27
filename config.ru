require 'dashing'
require 'dotenv'
require "redis"

Dotenv.load

configure :development do
  $redis = Redis.new()
end

configure :production do
    uri = URI.parse(ENV["REDISGREEN_URL"])
    $redis = Redis.new(url: ENV["REDISGREEN_URL"], driver: :hiredis)
end

configure do
  set :auth_token, ENV['AUTH_TOKEN']
  set :default_dashboard, 'main'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end

  $redis.setnx('servers', [].to_json)
end

post '/add_server' do
  request.body.rewind
  body = JSON.parse(request.body.read)
  auth_token = body.delete("auth_token")
  if !settings.auth_token || settings.auth_token == auth_token
    urls = JSON.parse($redis.get('servers'))
    if body['url'] =~ URI::regexp
      urls << body['url']
      $redis.set('servers', urls.to_json)
    end
    204
  else
    status 401
    "Invalid API key\n"
  end
end

post '/remove_server' do
  request.body.rewind
  body = JSON.parse(request.body.read)
  auth_token = body.delete("auth_token")
  if !settings.auth_token || settings.auth_token == auth_token
    urls = JSON.parse($redis.get('servers'))
    urls.delete(body['url'])
    $redis.set('servers', urls.to_json)
    204
  else
    status 401
    "Invalid API key\n"
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
