class Server < Struct.new(:id, :funpack, :state, :slots, :players, :heartbeat)
end

class Servers < Array
  def initialize bus
    @bus = bus
  end

  def update!
    self.clear
    @server_info = @bus.server_info

    @server_info.each do |s|
      self << Server.new(
        s[:id],
        s[:funpack],
        s[:state],
        s[:slots],
        s[:players],
        s[:heartbeat]
      )
    end
  end

  def players
    self.inject([]) {|a, s| a + s.players }.uniq
  end

  def slots
    self.inject(0) {|count, s| count + (s.slots || 1) }
  end

  def find_id(id)
    self.find{|s| s.id == id }
  end

  def reallocate!(id, slots, message)
    @bus.brain_request(
      'servers:reallocate_request',
      server_id: id,
      slots: slots,
      message: message
    )
  end

  def del_server_info(id)
    @bus.del_server_keys(id)
  end
end