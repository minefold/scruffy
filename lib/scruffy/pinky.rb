class Pinky
  attr_reader :id, :state, :free_disk_mb, :free_ram_mb, :idle_cpu
  attr_reader :servers

  def initialize id, state, free_disk_mb, free_ram_mb, idle_cpu, servers
    @id = id
    @state = state
    @free_disk_mb = free_disk_mb
    @free_ram_mb = free_ram_mb
    @idle_cpu = idle_cpu
    @servers = servers
  end
  
  def up?
    state == :up
  end

  def stopping?
    state == :stopping
  end
end
