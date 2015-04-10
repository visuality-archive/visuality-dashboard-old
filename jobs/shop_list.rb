SCHEDULER.every '30s', :first_in => 0 do
  output = []

  if $redis.exists("shop")
    $redis.sscan_each("shop") do |item|
      output << item
    end
  end

  send_event('shop', { items: output })
end
