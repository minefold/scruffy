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
end
