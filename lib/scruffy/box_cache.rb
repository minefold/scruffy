class BoxCacheEntry
  attr_reader :id, :state, :transitioned_at

  def self.deserialize entry
    new(entry[:id], entry[:state], Time.at(entry[:transitioned_at]))
  end

  def initialize id, state, transitioned_at
    @id = id
    @state = state
    @transitioned_at = transitioned_at
  end

  def serialize
    {
      id: id,
      state: state,
      transitioned_at: transitioned_at.to_i
    }
  end
end

class BoxesCache < Array
  def self.deserialize entries
    new((entries||[]).map{|entry| BoxCacheEntry.deserialize(entry) })
  end

  def ids
    map(&:id)
  end
  
  def by_id id
    find{|entry| entry.id == id }
  end

  def serialize
    map {|entry| entry.serialize }
  end
end