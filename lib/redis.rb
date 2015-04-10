require "redis"

if ENV["REDISCLOUD_URL"].nil?
  $redis = Redis.new
else
  uri = URI.parse(ENV["REDISCLOUD_URL"])
  $redis = Redis.new(url: ENV["REDISCLOUD_URL"], driver: :hiredis)
end

