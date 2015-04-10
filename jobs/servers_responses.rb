require "net/http"
require "net/https"

SCHEDULER.every '30s', :first_in => 0 do
  output_hash = Hash.new({ value: 0 })

  if $redis.exists("servers")
    urls = []
    $redis.sscan_each("servers") do |item|
      urls << item
    end

    urls.each do |url|
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Get.new(uri.request_uri)

      begin
        response = http.request(request)
        if response.is_a? Net::HTTPSuccess
          output_hash[url] = {label: url, value: 'OK' }
        elsif response.is_a? Net::HTTPRedirection
          output_hash[url] = {label: url, value: 'REDIRECTION' }
        else
          output_hash[url] = {label: url, value: 'ERROR' }
        end
      rescue Exception => e
         output_hash[url] = {label: url, value: 'BAD URL' }
      end
    end
  end
  send_event('servers', { items: output_hash.values })
end
