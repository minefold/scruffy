class Box
  attr_reader :id, :ip, :type, :state, :started_at, :tags

  def initialize id, ip, type, state, started_at, tags = {}
    @id = id
    @ip = ip
    @type = type
    @state = state
    @started_at = started_at
    @tags = tags
  end

  def self.deserialize h
    new(
      h[:id],
      h[:ip],
      h[:type],
      h[:state],
      Time.at(h[:started_at]),
      h[:tags])
  end
  
  def serialize
    {
      id: id,
      ip: ip,
      type: type,
      state: state,
      started_at: started_at.to_i
    }
  end
  
  def uptime_mins
    ((Time.now - started_at) / 60.0).floor
  end
end
