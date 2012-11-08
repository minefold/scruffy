require 'eventmachine/multi'

module Scruffy
  class RedisUniverse
    def self.collect timeout = 10, *c, &b
      cb = EM::Callback(*c, &b)
      redis = Prism.redis

      @timeout = EM.add_periodic_timer(timeout) {
        puts "timeout collecting redis state"
        EM.stop
      }

      pinky_heartbeats = {}
      op0 = EM::DefaultDeferrable.new
      redis.keys("pinky/*/heartbeat") do |keys|
        EM::Iterator.new(keys).each(proc{|key, iter|
          pinky_id = key.split('/')[1]
          redis.get_json(key) do |pinky_info|
            pinky_heartbeats[pinky_id] = pinky_info
            iter.next
          end
        }, proc { op0.succeed })
      end

      pinky_states = {}
      op1 = EM::DefaultDeferrable.new
      redis.keys("pinky/*/state") do |keys|
        EM::Iterator.new(keys).each(proc{|key, iter|
          pinky_id = key.split('/')[1]
          redis.get(key) do |state|
            pinky_states[pinky_id] = state
            iter.next
          end
        }, proc { op1.succeed })
      end

      server_states = {}
      op2 = EM::DefaultDeferrable.new
      redis.keys("server/state/*") do |keys|
        EM::Iterator.new(keys).each(proc{|key, iter|
          server_id = key.split('/')[2]
          redis.get(key) do |state|
            server_states[server_id] = state
            iter.next
          end
        }, proc { op2.succeed })
      end

      pinky_servers = {}
      op3 = EM::DefaultDeferrable.new
      redis.keys("pinky/*/servers/*") do |keys|
        EM::Iterator.new(keys).each(proc{|key, iter|
          _, pinky_id, _, server_id = key.split('/')

          pinky_servers[pinky_id] ||= []
          pinky_servers[pinky_id] << server_id
          iter.next
        }, proc { op3.succeed })
      end


      multi = EventMachine::Multi.new
      multi.add :op0,         op0
      multi.add :op1,         op1
      multi.add :op2,         op2
      multi.add :op3,         op3
      multi.add :scruffy_pinkies, redis.get_json_df('scruffy/pinkies')
      multi.add :scruffy_servers, redis.get_json_df('scruffy/servers')
      multi.add :players,         redis.hgetall('players:playing')

      multi.callback do |results|
        @timeout.cancel

        pinkies = {}
        pinky_heartbeats.each do |pinky_id, heartbeat|
          servers = (pinky_servers[pinky_id] || []).inject({}) do |h, server_id|
            h[server_id] = {
              state: server_states[server_id]
            }
            h
          end
          pinkies[pinky_id] = heartbeat.merge(
            state: pinky_states[pinky_id],
            servers: servers,
          ).symbolize_keys
        end

        cb.call RedisUniverse.new pinkies, 
          results[:scruffy_pinkies] || {}, 
          results[:scruffy_servers] || {}, 
          results[:players] || {}
      end
      cb
    end

    attr_reader :pinkies, :scruffy_pinkies, :scruffy_servers, :players
    
    # pinkies holds the new values
    # scruffy_pinkies and scruffy_servers are previous values recorded
    # by scruffy
    def initialize pinkies, scruffy_pinkies, scruffy_servers, players
      @pinkies = pinkies
      @scruffy_pinkies = scruffy_pinkies
      @scruffy_servers = scruffy_servers
      @players = players
      
      @pinkies.each do |pinky_id, pinky|
        pinky[:players] = []
        
        pinky[:servers].each do |server_id, s|
          s[:players] = @players.inject([]) do |a, (player_id, sid)| 
            if server_id == sid
              a << player_id
              pinky[:players] << player_id
            end
          end
        end
      end
    end
    
    def server_players(server_id)
      
    end
  end
end