class Pinkies < Array
  def initialize bus
    @bus = bus
  end

  def update!
    self.clear
    pinky_states = @bus.pinky_states
    pinky_servers = @bus.pinky_servers
    server_states = @bus.server_states

    @bus.pinky_heartbeats.each do |hb|
      server_state = pinky_states.find{|ps| ps[:id] == hb[:id]}
      state = server_state[:state]

      servers = pinky_servers.select{|ps| ps[:pinky_id] == hb[:id] }.map do |ps|
        Server.new(
          ps[:id],
          server_states.find{|ss| ss[:id] == ps[:id]}[:state],
          ps[:port]
        )
      end

      self << Pinky.new(
        hb[:id],
        state,
        hb[:free_disk_mb],
        hb[:free_ram_mb],
        hb[:idle_cpu],
        servers
      )
    end

  end

  def ids
    map(&:id)
  end

  def pinky_down! id
    @bus.set_pinky_state id, :down
  end
end