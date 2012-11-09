# tracks an entity state changes
class EntityStateChange
  attr_reader :id, :state, :changed_at

  def initialize id, state, changed_at
    @id = id
    @state = state
    @changed_at = changed_at
  end

  def duration
    Time.now - changed_at
  end

  def self.deserialize h
    new(
      h[:id],
      h[:state],
      Time.at(h[:changed_at])
    )
  end

  def serialize
    {
      id: id,
      state: state,
      changed_at: changed_at.to_i
    }
  end
end

class EntityStateCache < Array
  def self.deserialize entries
    new((entries||[]).map{|entry| EntityStateChange.deserialize(entry) })
  end

  def serialize
    map {|entry| entry.serialize }
  end

  def ids
    map {|entry| entry.id }
  end
end