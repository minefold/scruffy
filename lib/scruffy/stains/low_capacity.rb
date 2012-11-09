# severity: minor

# causes:
#   getting low on available pinkies

# smell:
#   there is less than 3 server slots available

# cleanup:
#   start a new box

class LowCapacity < Stain
  ECUS_PER_SERVER = 1.5
  RAM_MB_PER_SERVER = 256
  SERVER_BUFFER = 3

  def clean
    if !capacity?
      log.warn event: 'low_capacity',
        used: server_slots_used,
        available: server_slots_available,
        action: 'starting new box'

      start_new_box
    end
  end
  
  def capacity?
    boxes.starting.any? || (server_slots_available > SERVER_BUFFER)
  end
  
  def start_new_box
    boxes.start_new(BoxType.find('c1.xlarge'))
  end

  def server_slots_available
    pinkies.inject(0) do |sum, pinky|
      box = boxes.by_id(pinky.id)
      sum + (box.type.ecus / ECUS_PER_SERVER).floor
    end
  end

  def server_slots_used
    pinkies.inject(0) do |sum, pinky|
      box = boxes.by_id(pinky.id)

      sum + pinky.servers.count
    end
  end
end