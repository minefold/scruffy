# causes:
#   unknown

# smell:
#   server in starting state longer than 5 minutes

# cleanup:

# report:
#    worlds affected
#    players affected

class ServerStartFrozen < Stain
  def clean
    no_longer_frozen_server_ids.each do |server_id|
      log.warn event: 'server_no_longer_frozen', id: server_id
      forget server_id
    end

    currently_frozen_servers.each do |stain, server|
      if stain.duration > 5 * 60
        log.warn event: 'server_start_frozen',
          id: stain.id,
          action: 'cancelling'

        @bus.del_server_state stain.id

      elsif stain.duration > 1 * 60
        log.info event: 'server_start_frozen',
          id: stain.id,
          duration: stain.duration
      end
    end

    new_frozen_servers.each do |server|
      notice server.id
    end
  end

  def new_frozen_servers
    (empty_shared_server_ids - noticed.ids).map do |server_id|
      @servers.find_id(server_id)
    end
  end

  def currently_frozen_servers
    noticed.map do |stain|
      [stain, @servers.find_id(stain.id)]
    end
  end

  def no_longer_frozen_server_ids
    (noticed.ids - empty_shared_server_ids)
  end

  def empty_shared_server_ids
    (@servers.ids & bus.shared_server_ids).select do |id|
      @servers.find_id(id).players.size == 0
    end
  end

  def noticed
    @stains_cache.in_state(:shared_server_empty)
  end

  def notice id
    @stains_cache << EntityStateChange.new(
      id,
      :shared_server_empty,
      Time.now
    )
  end

  def forget id
    @stains_cache.delete(id)
  end
end