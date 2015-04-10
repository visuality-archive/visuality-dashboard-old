require 'dotenv'
require 'haml'

# Load the ENV vars first
Dotenv.load

require 'dashing'

# Check key types and remove them if they're deprecated
if $redis.type("servers") != "set"
  $redis.del("servers")
end

if $redis.type("shop") != "set"
  $redis.del("shop")
end

configure do
  set :auth_token, ENV['AUTH_TOKEN']
  set :default_dashboard, 'main'

  helpers do
    def check_request_authentication?(body)
      auth_token = body.delete("auth_token")
      !settings.auth_token || settings.auth_token == auth_token ? true : false
    end
  end
end

post '/add_server' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    if body['url'] =~ URI::regexp
      if $redis.sadd("servers", body["url"])
        status 204
      else
        status 304
      end
    else
      401
      "Invalid URL key\n"
    end
  else
    401
    "Invalid API key\n"
  end
end

post '/remove_server' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    if $redis.srem("servers", body["url"])
      status 204
    else
      status 304
    end
  else
    401
    "Invalid API key\n"
  end
end

post '/add_to_shop_list' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    if $redis.sadd("shop", body["key"])
      status 204
    else
      status 304
    end
  else
    401
    "Invalid API key\n"
  end
end

post '/remove_from_shop_list' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    if $redis.srem("shop", body["key"])
      status 204
    else
      status 304
    end
  else
    401
    "Invalid API key\n"
  end
end

post '/clear_shop_list' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    $redis.del('shop')
    status 204
  else
    401
    "Invalid API key\n"
  end
end


map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end


run Sinatra::Application
