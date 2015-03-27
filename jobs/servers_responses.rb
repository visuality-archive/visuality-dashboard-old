require "net/http"
require "net/https"

SCHEDULER.every '30s', :first_in => 0 do
  urls = JSON.parse($redis.get('servers'))
  bads_urls = Hash.new({ value: 0 })
  urls.each do |url|
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    if response.is_a? Net::HTTPSuccess
      bads_urls[url] = {label: url, value: 'OK' }
    elsif response.is_a? Net::HTTPRedirection
      bads_urls[url] = {label: url, value: 'REDIRECTION' }
    else
      bads_urls[url] = {label: url, value: 'ERROR' }
    end
  end
  send_event('servers', { items: bads_urls.values })
end
