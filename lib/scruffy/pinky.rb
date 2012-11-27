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
end
