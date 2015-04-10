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

    def protected!
      unless authorized?
        response["WWW-Authenticate"] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      if ENV["HTTP_AUTH_USER"] && ENV["HTTP_AUTH_PASS"]
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV["HTTP_AUTH_USER"], ENV["HTTP_AUTH_PASS"]]
      else
        true
      end
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
      status 401
      "Invalid URL key\n"
    end
  else
    status 401
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
    status 401
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
    status 401
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
    status 401
    "Invalid API key\n"
  end
end

post '/clear_shop_list' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    $redis.del('shop')
    status 204
  else
    status 401
    "Invalid API key\n"
  end
end

post '/add_conference' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    list = []

    if $redis.exists("conferences")
      list = JSON.parse($redis.get("conferences"))
    end

    list << {
      title: body["title"],
      date: body["date"],
      url: body["url"]
    }

    $redis.set("conferences", list.to_json)
    status 204
  else
    status 401
    "Invalid API key\n"
  end
end

post '/remove_conference' do
  body = JSON.parse(request.body.read)
  if check_request_authentication?(body)
    list = []

    if $redis.exists("conferences")
      list = JSON.parse($redis.get("conferences"))
    end

    list.reject! do |item|
      item["title"] == body["title"]
    end

    $redis.set("conferences", list.to_json)
    status 204
  else
    status 401
    "Invalid API key\n"
  end

end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
