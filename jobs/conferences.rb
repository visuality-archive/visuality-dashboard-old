SCHEDULER.every "30s", first_in: 0 do
  list = []

  if $redis.exists("conferences")
    list = JSON.parse($redis.get("conferences"))
  end

  send_event("conferences", {conferences: list})
end

