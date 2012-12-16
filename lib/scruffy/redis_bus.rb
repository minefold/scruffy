require 'json'

# this is responsible for querying the state of the "universe" using redis as
# it's implementation
# the universe is the entire system, all processes on all machines

class RedisBus
  def redis
    @redis ||= begin
      uri = URI.parse(ENV['REDIS_URL'] || 'redis://localhost:6379/')
      Redis.new(host: uri.host, port: uri.port, password: uri.password, driver: :hiredis)
    end
  end

  def pinky_heartbeats
    redis.keys("pinky:*:heartbeat").map do |key|
      id = key.split(':')[1]
      json = redis.get(key)
      begin
        JSON.load(json).merge(id: id).symbolize_keys
      rescue => e
        puts "JSON error #{e}\n#{e.backtrace}"
        {}
      end
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

      JSON.load(redis.get(key) || "{}").merge(
        id: server_id,
        pinky_id: pinky_id,
      ).symbolize_keys
    end
  end

  def server_info
    redis.keys("server:*:state").map do |key|
      server_id = key.split(':')[1]
      {
        id: server_id,
        state: redis.get("server:#{server_id}:state"),
        slots: as_int(redis.get("server:#{server_id}:slots")),
        players: redis.smembers("server:#{server_id}:players"),
        heartbeat: redis.get("server:#{server_id}:heartbeat"),
      }
    end
  end

  def del_server_info(server_id)
    redis.del("server:#{server_id}:state")
    redis.del("server:#{server_id}:players")
    redis.del("server:#{server_id}:slots")
  end

  def set_server_state id, state
    redis.set("server:#{id}:state", state)
  end

  def del_server_keys id
    redis.del(
      "server:#{id}:state",
      "server:#{id}:players",
      "server:#{id}:slots",
      "server:#{id}:restart"
    )
  end

  def del_pinky_server pinky_id, server_id
    redis.del("pinky:#{pinky_id}:servers:#{server_id}")
  end

  def store_cache(name, cache)
    redis.set("scruffy:cache:#{name}", JSON.dump(cache))
  end

  def cache(name)
    json = redis.get("scruffy:cache:#{name}")
    JSON.load(json).symbolize_keys if json
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

  def brain_request type, args = {}
    redis.lpush type, JSON.dump(args)
  end

  # TODO this stuff belongs in Minefold not Party Cloud
  def shared_server_ids
    redis.smembers("servers:shared")
  end

  def del_shared_server server_id
    redis.srem("servers:shared", server_id)
  end

  # returns the number to_i or nil
  def as_int(number)
    number and number.to_i
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