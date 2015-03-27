SCHEDULER.every '30s', :first_in => 0 do
  output = Hash.new({ value: 0 })
  list = $redis.hgetall "shop"
  list.each do |item|
    output[item[0]] = {label: item[0], value: item[1] }
  end
  send_event('shop', { items: output.values })
end
