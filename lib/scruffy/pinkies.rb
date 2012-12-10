class Pinkies < Array
  def initialize bus
    @bus = bus
  end

  def update!
    self.clear
    @states = @bus.pinky_states
    @pinky_servers = @bus.pinky_servers
    @heartbeats = @bus.pinky_heartbeats

    (heartbeat_ids | pinky_state_ids | pinky_server_pinky_ids).each do |pinky_id|
      hb = @heartbeats.find{|hb| hb[:id] == pinky_id}

      server_ids = @pinky_servers.
        select{|ps| ps[:pinky_id] == pinky_id }.
        map{|ps| ps[:id] }

      state = @states.find{|ps| ps[:id] == pinky_id}
      self << Pinky.new(
        pinky_id,
        state && state[:state],
        hb && hb[:freeDiskMb],
        hb && hb[:freeRamMb],
        hb && hb[:idleCpu],
        server_ids
      )
    end

  end

  def heartbeat_ids
    @heartbeats.map{|hb| hb[:id]}
  end

  def pinky_state_ids
    @states.map{|ps| ps[:id]}
  end

  def pinky_server_pinky_ids
    @pinky_servers.group_by{|ps| ps[:pinky_id]}.keys
  end

  def find_by_server_id(server_id)
    self.find {|p| p.server_ids.include?(server_id) }
  end

  def server_ids
    self.inject([]) {|ids, pinky| ids + pinky.server_ids }.uniq
  end

  def servers
    self.map(&:servers).flatten
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
    @bus.del_shared_server(server_id)
  end

  def reallocate_server! pinky_id, server_id, slots
    @bus.brain_request 'servers:reallocate_request', JSON.dump(
      server_id: server_id,
      slots: slots
    )

  end

  def list_server! pinky_id, server_id
    @bus.queue_pinky_job pinky_id, 'list', serverId: server_id
  end
end