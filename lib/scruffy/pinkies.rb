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
        ss = server_states.find{|ss| ss[:id] == ps[:id]}

        Server.new(
          ps[:id],
          ss && ss[:state],
          ps[:port]
        )
      end

      state = @states.find{|ps| ps[:id] == pinky_id}
      self << Pinky.new(
        pinky_id,
        state && state[:state],
        hb && hb['freeDiskMb'],
        hb && hb['freeRamMb'],
        hb && hb['idleCpu'],
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

  def server_ids
    self.inject([]) {|ids, pinky| (ids << pinky.servers.ids).flatten }
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

  def stop_server! pinky_id, server_id
    @bus.queue_pinky_job pinky_id, 'stop', serverId: server_id
  end
end