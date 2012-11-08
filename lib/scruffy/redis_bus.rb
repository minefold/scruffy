require 'json'

# this is responsible for querying the state of the "universe" using redis as
# it's implementation
# the universe is the entire system, all processes on all machines

class RedisBus
  def redis
    @redis ||= Redis.new(:host => "0.0.0.0", :port => 6379, :driver => :hiredis)
  end

  def pinky_heartbeats
    redis.keys("pinky/*/heartbeat").map do |key|
      id = key.split('/')[1]
      JSON.load(redis.get(key)).merge(id: id)
    end
  end

  def pinky_states
    redis.keys("pinky/*/state").map do |key|
      pinky_id = key.split('/')[1]
      {
        id: pinky_id,
        state: redis.get(key)
      }
    end
  end

  def pinky_servers
    redis.keys("pinky/*/servers/*").map do |key|
      _, pinky_id, _, server_id = key.split('/')

      JSON.load(redis.get(key)).merge(
        id: server_id,
        pinky_id: pinky_id,
      )
    end

  end

  def server_states
    redis.keys("server/state/*").map do |key|
      server_id = key.split('/')[2]
      {
        id: server_id,
        state: redis.get(key)
      }
    end
  end
  
  def boxes_cache
    json = redis.get("scruffy/cache/boxes")
    JSON.load(json).symbolize_keys if json
  end
  
  def store_boxes_cache cache
    redis.set("scruffy/cache/boxes", JSON.dump(cache))
  end
end

# bus.expect(:pinky_heartbeats, [
#   id: "i-12345",
#   free_disk_mb: 73132,
#   free_ram_mb: 632,
#   idle_cpu: 88,
# ])
# bus.expect(:pinky_states, [
#   id: "i-12345",
#   state: "up",
# ])
# bus.expect(:pinky_servers, [{
#   id: "6789",
#   pinky_id: "i-12345",
#   port: 10000,
# },  {
#   id: "7201",
#   pinky_id: "i-12345",
#   port: 10100,
# }])
# bus.expect(:server_states, [{
#   id: "6789",
#   state: "up",
# },  {
#   id: "7201",
#   state: "up",
# }])