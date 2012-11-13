class Pinkies < Array
  attr_accessor :states, :servers, :server_states, :heartbeats
  
  def initialize bus
    @bus = bus
  end

  def update!
    self.clear
    @states = @bus.pinky_states
    @servers = @bus.pinky_servers
    @server_states = @bus.server_states
    @heartbeats = @bus.pinky_heartbeats

    (heartbeat_ids | pinky_state_ids).each do |pinky_id|
      hb = @heartbeats.find{|hb| hb[:id] == pinky_id}

      servers = @servers.select{|ps| ps[:pinky_id] == pinky_id }.map do |ps|
        Server.new(
          ps[:id],
          server_states.find{|ss| ss[:id] == pinky_id}[:state],
          ps[:port]
        )
      end

      state = @states.find{|ps| ps[:id] == pinky_id}
      self << Pinky.new(
        pinky_id,
        state && state[:state],
        hb && hb[:free_disk_mb],
        hb && [:free_ram_mb],
        hb && [:idle_cpu],
        servers
      )
    end
    
  end
  
  def heartbeat_ids
    @heartbeats.map{|hb| hb[:id]}
  end

  def pinky_state_ids
    @states.map{|ps| ps[:id]}
  end

  def pinky_starting! id
    @bus.set_pinky_state id, :starting
    update!
  end

  def pinky_stopping! id
    @bus.set_pinky_state id, :stopping
    update!
  end

  def pinky_down! id
    @bus.set_pinky_state id, :down
    update!
  end
  
  def delete! id
    @bus.del_pinky_state id
  end
end