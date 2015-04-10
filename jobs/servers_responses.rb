require "net/http"
require "net/https"

SCHEDULER.every '30s', :first_in => 0 do
  output = []

  if $redis.exists("servers")
    $redis.sscan_each("servers") do |url|
      begin
        destination_url, response = fetch(url)
        if url == destination_url
          output << {label: url, value: response }
        else
          output << {label: url, value: "REDIRECTION (#{destination_url} - #{response})"}
        end
      rescue StandardError => e
        output << {label: url, value: 'BAD URL' }
      end
    end
  end

  send_event('servers', { items: output })
end

def fetch(url, limit = 10)
  return url, 'HTTP redirect too deep' if limit == 0

  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.scheme == 'https'
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  request = Net::HTTP::Get.new(uri.request_uri)
  response =   http.request(request)

  case response
  when Net::HTTPSuccess
    return url, 'OK'
  when Net::HTTPRedirection
    return fetch(response['location'], limit - 1)
  else
    return url, response.code
  end
end
