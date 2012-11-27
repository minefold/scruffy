# causes:
#   too many players in server

# smell:
#   more players in server than slots allocated

# cleanup:
#   reallocate server

# report:

class ServerUnderAllocated < Stain
  def clean
    no_longer_under_allocated_server_ids.each do |server_id|
      log.warn event: 'server_allocated_ok', id: server_id
      forget server_id
    end

    currently_under_allocated_servers.each do |stain, server|
      required = allocator.slots_required(server.players.size)
      slot_difference = required - server.slots

      if stain.duration > 5 * 60 or slot_difference > 1
        log.warn event: 'server_under_allocated',
          id: stain.id,
          action: 'reallocating',
          slots: server.slots,
          required: required

      else
        log.info event: 'server_under_allocated',
          id: stain.id,
          duration: stain.duration,
          slots: server.slots,
          required: required
      end
    end

    new_under_allocated_servers.each do |server|
      log.warn event: 'server_under_allocated', id: server.id
      notice server.id
    end
  end

  def new_under_allocated_servers
    (under_allocated_servers.ids - noticed.ids).map do |server_id|
      @servers.find_id(server_id)
    end
  end

  def currently_under_allocated_servers
    noticed.map do |stain|
      [stain, @servers.find_id(stain.id)]
    end
  end

  def no_longer_under_allocated_server_ids
    (noticed.ids - under_allocated_servers.ids)
  end

  def under_allocated_servers
    @servers.select do |server|
      player_slots_available =
        (server.slots || 1) * allocator.players_per_slot

      server.players.size > player_slots_available
    end
  end

  def noticed
    @stains_cache.in_state(:server_under_allocated)
  end

  def reallocating
    @stains_cache.in_state(:server_under_allocated)
  end

  def notice id
    @stains_cache << EntityStateChange.new(
      id,
      :server_under_allocated,
      Time.now
    )
  end

  def forget id
    @stains_cache.delete(id)
  end
end