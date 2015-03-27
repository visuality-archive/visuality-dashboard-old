require 'dashing'
require 'dotenv'
require 'haml'
require "redis"

Dotenv.load

if ENV["REDISCLOUD_URL"].nil?
  $redis = Redis.new
else
  uri = URI.parse(ENV["REDISCLOUD_URL"])
  $redis = Redis.new(url: ENV["REDISCLOUD_URL"], driver: :hiredis)
end

configure do
  set :auth_token, ENV['AUTH_TOKEN']
  set :default_dashboard, 'main'

  helpers do
    def check_request_authentication?(body)
      auth_token = body.delete("auth_token")
      !settings.auth_token || settings.auth_token == auth_token ? true : false
    end

    def add_to_redis(key, value)
      values = JSON.parse($redis.get(key))
      values << value
      $redis.set(key, values.to_json)
    end

    def remove_from_redis(key, value)
      values = JSON.parse($redis.get(key))
      values.delete(value)
      $redis.set(key, values.to_json)
    end
  end

  $redis.setnx('servers', [].to_json)
  $redis.mapped_hmset('shop', {'piwko' => 'skrzynka'})
end

post '/add_server' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    if body['url'] =~ URI::regexp
      add_to_redis('servers', body['url'])
      204
    else
      status 401
      "Invalid API key\n"
    end
  end
end

post '/remove_server' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    remove_from_redis('servers', body['url'])
    204
  else
    status 401
    "Invalid API key\n"
  end
end

post '/add_to_shop_list' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    $redis.mapped_hmset('shop', {body['key'] => body['value']})
    204
  else
    status 401
    "Invalid API key\n"
  end
end

post '/remove_to_shop_list' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    $redis.hdel('shop', body['key'])
    204
  else
    status 401
    "Invalid API key\n"
  end
end

post '/clear_shop_list' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    $redis.del('shop')
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
