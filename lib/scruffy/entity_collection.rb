class Array
  def ids
    map(&:id)
  end

  def by_id id
    find{|e| e.id == id}
  end

  def pending
    in_state :pending
  end

  def starting
    in_state :starting
  end

  def up
    in_state :up
  end

  def stopping
    in_state :stopping
  end

  def in_state state
    self.select{|b| b.state.to_s == state.to_s }
  end
end