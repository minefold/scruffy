# enough capacity is more than 3 server slots available or boxes/pinkies starting
class Allocator
  ECUS_PER_SERVER = 1.5
  RAM_MB_PER_SERVER = 256
  SERVER_BUFFER = 3

  def initialize boxes, pinkies
    @boxes, @pinkies = boxes, pinkies
  end

  def low_capacity?
    !@boxes.starting.any? &&
      !@pinkies.starting.any? &&
      (total_server_slots <= SERVER_BUFFER)
  end

  def total_server_slots
    @pinkies.inject(0) do |sum, pinky|
      box = @boxes.by_id(pinky.id)
      if box.nil?
        sum
      else
        sum + slot_count(box)
      end
    end
  end

  def server_slots_used
    @pinkies.inject(0) do |sum, pinky|
      box = @boxes.by_id(pinky.id)

      sum + pinky.servers.count
    end
  end

  def excess_pinkies
    excess_slots = total_server_slots - SERVER_BUFFER
    idle_pinkies_close_to_hour_end.select do |pinky|
      box = @boxes.by_id(pinky.id)

      excess_slots -= box.type.server_slots

      excess_slots >= 0
    end

  end

  def idle_pinkies_close_to_hour_end
    idle_pinkies.select do |pinky|
      box = @boxes.by_id(pinky.id)
      box.uptime_mins % 60 > 55
    end
  end

  def idle_pinkies
    # pinkies that are up, have no players, no worlds and are accepting new worlds
    @pinkies.select do |pinky|
      pinky.up?

      # uptime_minutes = box.uptime
      # TODO players
      # player_count = box[:players].size
       # world_count = instanceType.size

      # player_count == 0 && world_count == 0 && !keepalive?(box)
    end
  end

  def slot_count box
    (box.type.ecus / ECUS_PER_SERVER).floor
  end
  
  def new_box_type
    BoxType.find('c1.xlarge')
  end
end