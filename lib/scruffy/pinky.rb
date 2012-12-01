class Pinky < Struct.new(:id, :state, :free_disk_mb, :free_ram_mb, :idle_cpu, :server_ids)

  def up?
    state == :up
  end

  def stopping?
    state == :stopping
  end

  def down?
    state == :down
  end
  
  def count_slots(servers)
    server_ids.map {|sid| servers.find_id(sid) }.compact.
      inject(0) {|count, s| count + (s.slots || 1) }
  end
  
end
