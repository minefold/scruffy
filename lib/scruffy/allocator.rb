# enough capacity is more than 3 server slots available or boxes/pinkies starting
class Allocator
  ECUS_PER_SLOT = ((ENV['ECUS_PER_SLOT'] and ENV['ECUS_PER_SLOT'].to_i) || 1)
  RAM_MB_PER_SLOT = (
    (ENV['RAM_MB_PER_SLOT'] and ENV['RAM_MB_PER_SLOT'].to_i) || 512)
  SERVER_BUFFER = ((ENV['SERVER_BUFFER'] and ENV['SERVER_BUFFER'].to_i) || 5)
  RAM_ALLOCATION = (
    (ENV['RAM_ALLOCATION'] and ENV['RAM_ALLOCATION'].to_f) || 0.9)
  PLAYERS_PER_SLOT = (
    (ENV['PLAYERS_PER_SLOT'] and ENV['PLAYERS_PER_SLOT'].to_i) || 5)

  def initialize boxes, pinkies, servers
    @boxes, @pinkies, @servers = boxes, pinkies, servers
  end

  def low_capacity?
    !@boxes.pending.any? &&
      !@boxes.starting.any? &&
      !@pinkies.starting.any? &&
      (available_server_slots <= SERVER_BUFFER)
  end

  def available_pinky_slots
    @pinkies.inject(0) do |sum, pinky|
      box = @boxes.by_id(pinky.id)
      if box.nil? or not box.up? or not pinky.up?
        sum
      else
        sum + slot_count(box.type)
      end
    end
  end

  def available_server_slots
    available_pinky_slots - used_server_slots
  end

  def used_server_slots
    # only count up pinkies
    @pinkies.inject(0) do |sum, pinky|
      box = @boxes.by_id(pinky.id)
      if box.nil? or not box.up? or not pinky.up?
        sum
      else
        sum + pinky.count_slots(@servers)
      end
    end
  end

  def excess_pinkies
    excess_slots = available_pinky_slots - SERVER_BUFFER
    idle_pinkies_close_to_hour_end.select do |pinky|
      box = @boxes.by_id(pinky.id)

      excess_slots -= slot_count(box.type)

      excess_slots >= 0
    end

  end

  def idle_pinkies_close_to_hour_end
    idle_pinkies.select do |pinky|
      box = @boxes.by_id(pinky.id)
      box and box.uptime_mins % 60 > 55
    end
  end

  def idle_pinkies
    # pinkies that are up, have no servers and are accepting new worlds
    @pinkies.select do |pinky|
      (pinky.up? || pinky.stopping? || pinky.down?) and pinky.server_ids.size == 0
    end
  end

  def allocated_ram_mb box_type
    (box_type.ram_mb * RAM_ALLOCATION)
  end

  def slot_count box_type
    [(allocated_ram_mb(box_type) / RAM_MB_PER_SLOT).floor,
     (box_type.ecus / ECUS_PER_SLOT).floor].min
  end

  def players_per_slot
    PLAYERS_PER_SLOT
  end

  def new_box_type
    BoxType.find(ENV['INSTANCE_TYPE'] || 'cc2.8xlarge')
  end

  def slots_required player_count
    player_count = [player_count, 1].max

    slots = (player_count / players_per_slot.to_f).ceil

    # we want slots to be exponential. 1, 2, 4, etc up to 16 slots
    [2 ** Math.log(slots, 2).ceil, 16].min
  end
end