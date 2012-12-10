# causes:
#   not enough players in server

# smell:
#   less players in server than slots allocated

# cleanup:
#   reallocate server

# report:

class ServerOverAllocated < Stain
  include StainWatcher

  stain :server_over_allocated

  def affected_ids
    @servers.select do |server|
      player_slots_available =
        (server.slots || 1) * allocator.players_per_slot

      server.players.size < player_slots_available
    end.ids
  end

  def stain_gone(stain_id)
    log.info event: 'server_allocated_ok', id: server_id
  end

  def check_stain(stain)
    server = @servers.find_id(stain.id)
    required = allocator.slots_required(server.players.size)
    slot_difference = Math.log(server.slots, 2) - Math.log(required, 2)

    if slot_difference > 2 && stain.duration > 30 * 60
      log.warn event: 'server_over_allocated',
        id: stain.id,
        action: 'reallocating',
        slots: server.slots,
        required: required

      @servers.reallocate!(stain.id, required, "Optimizing server. Please reconnect in 30 seconds")

    else
      log.info event: 'server_over_allocated',
        id: stain.id,
        duration: stain.duration,
        slots: server.slots,
        required: required
    end
  end
end