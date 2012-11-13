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
      h[:state] && h[:state].to_sym,
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
  def delete id
    delete_if{|entry| entry.id == id}
  end
  
  def update id, new_entry
    self.map!{|entry| entry.id == id ? new_entry : entry }
  end
  
  def diff! name, entities
    log = Logger.new
    (entities.ids - ids).each do |entity_id|
      log.info event: "#{name}_found", id: entity_id, action: 'adding to cache'

      entity = entities.by_id(entity_id)
      self << EntityStateChange.new(entity.id, entity.state, Time.now)
    end

    (ids - entities.ids).each do |entity_id|
      log.info event: "#{name}_gone", id: entity_id, action: 'removing from cache'

      self.delete entity_id
    end

    self.each do |entry|
      entity = entities.by_id(entry.id)
      if entry.state != entity.state
        log.info event: "#{name}_state_change", id: entity.id, 
          action: "#{entry.state} => #{entity.state}"

        self.update entity.id,
          EntityStateChange.new(entity.id, entity.state, Time.now)
      end
    end
  end

  def self.deserialize entries
    new((entries||[]).map{|entry| EntityStateChange.deserialize(entry) })
  end

  def serialize
    map {|entry| entry.serialize }
  end

end