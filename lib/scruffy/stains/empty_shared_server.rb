# TODO this logic belongs in Minefold not Party Cloud

# severity:
#   normal

# smell:
#   server is empty

# cleanup:
#   stop server after 1 minute of emptiness

class EmptySharedServer < Stain
  def clean
    no_longer_empty_server_ids.each do |server_id|
      log.warn event: 'server_no_longer_empty', id: server_id
      forget server_id
    end

    currently_empty_servers.each do |stain, server|
      if stain.duration > 1 * 60
        log.warn event: 'shared_server_empty',
          id: stain.id,
          action: 'shutting down'
          
        if pinky = pinkies.find {|p| p.server_ids.include?(server.id) }
          @pinkies.stop_server! pinky.id, server.id
          forget server.id
        end

      else
        log.info event: 'shared_server_empty',
          id: stain.id,
          duration: stain.duration
      end
    end

    new_empty_servers.each do |server|
      log.warn event: 'shared_server_empty', id: server.id
      notice server.id
    end
  end

  def new_empty_servers
    (empty_shared_server_ids - noticed.ids).map do |server_id|
      @servers.find_id(server_id)
    end
  end

  def currently_empty_servers
    noticed.map do |stain|
      [stain, @servers.find_id(stain.id)]
    end
  end

  def no_longer_empty_server_ids
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