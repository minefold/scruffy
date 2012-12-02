class Server < Struct.new(:id, :state, :slots, :players)
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
        s[:state],
        s[:slots],
        s[:players]
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
end