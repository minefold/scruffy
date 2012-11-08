class Server
  attr_reader :id, :state, :port
  
  def initialize id, state, port
    @id = id
    @state = state
    @port = port
  end
end