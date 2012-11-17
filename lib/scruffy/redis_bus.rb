require 'json'

# this is responsible for querying the state of the "universe" using redis as
# it's implementation
# the universe is the entire system, all processes on all machines

class RedisBus
  def redis
    uri = URI.parse(ENV['REDIS_URL'] || 'redis://localhost:6379/')
    @redis ||= Redis.new(host: uri.host, port: uri.port, password: uri.password, driver: :hiredis)
  end

  def pinky_heartbeats
    redis.keys("pinky:*:heartbeat").map do |key|
      id = key.split(':')[1]
      JSON.load(redis.get(key)).merge(id: id)
    end
  end

  def pinky_states
    redis.keys("pinky:*:state").map do |key|
      pinky_id = key.split(':')[1]
      {
        id: pinky_id,
        state: redis.get(key).to_sym
      }
    end
  end

  def set_pinky_state id, state
    redis.set("pinky:#{id}:state", state)
  end

  def del_pinky_state id
    redis.del("pinky:#{id}:state")
  end

  def pinky_servers
    redis.keys("pinky:*:servers:*").map do |key|
      _, pinky_id, _, server_id = key.split(':')

      JSON.load(redis.get(key)).merge(
        id: server_id,
        pinky_id: pinky_id,
      ).symbolize_keys
    end

  end

  def server_states
    redis.keys("server:*:state").map do |key|
      server_id = key.split(':')[1]
      {
        id: server_id,
        state: redis.get(key)
      }
    end
  end

  def boxes_cache
    json = redis.get("scruffy:cache:boxes")
    JSON.load(json).symbolize_keys if json
  end

  def store_boxes_cache cache
    redis.set("scruffy:cache:boxes", JSON.dump(cache))
  end

  def pinkies_cache
    json = redis.get("scruffy:cache:pinkies")
    JSON.load(json).symbolize_keys if json
  end

  def store_pinkies_cache cache
    redis.set("scruffy:cache:pinkies", JSON.dump(cache))
  end

  def stains_cache
    json = redis.get("scruffy:cache:stains")
    JSON.load(json).symbolize_keys if json
  end

  def store_stains_cache cache
    redis.set("scruffy:cache:stains", JSON.dump(cache))
  end

  def store_box_info id, ip, type, started_at, tags
    redis.set("box:#{id}", JSON.dump(
      id: id,
      ip: ip,
      type: type,
      started_at: started_at.to_i,
      tags: tags
    ))
  end

  def del_box_info id
    redis.del("box:#{id}")
  end
  
  def queue_pinky_job pinky_id, name, args = {}
    redis.lpush("pinky:#{pinky_id}:in", JSON.dump({
      name: name
    }.merge(args)))
  end

  # TODO this stuff belongs in Minefold not Party Cloud
  def shared_servers
    redis.smembers("servers:shared")
  end

  def connected_players
    redis.hgetall("players:playing")
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