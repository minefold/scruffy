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
    new_frozen_servers.each do |server|
      notice server.id
    end
    
    no_longer_frozen_server_ids.each do |server_id|
      log.warn event: 'server_no_longer_frozen', id: server_id
      forget server_id
    end

    currently_frozen_servers.each do |stain, server|
      if stain.duration > 5 * 60
        log.warn event: 'server_start_frozen',
          id: stain.id,
          action: 'cancelling'

        @bus.del_server_keys stain.id
        forget stain.id

      elsif stain.duration > 1 * 60
        log.info event: 'server_start_frozen',
          id: stain.id,
          duration: stain.duration
      end
    end
  end

  def new_frozen_servers
    (frozen_servers.ids - noticed.ids).map do |server_id|
      @servers.find_id(server_id)
    end
  end

  def currently_frozen_servers
    noticed.map do |stain|
      [stain, @servers.find_id(stain.id)]
    end
  end

  def no_longer_frozen_server_ids
    (noticed.ids - frozen_servers.ids)
  end

  def frozen_servers
    @servers.in_state('starting')
  end

  def noticed
    @stains_cache.in_state(:server_start_frozen)
  end

  def notice id
    @stains_cache << EntityStateChange.new(
      id,
      :server_start_frozen,
      Time.now
    )
  end

  def forget id
    @stains_cache.delete(id)
  end
end