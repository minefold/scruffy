# TODO this should be dependant on settings

# severity:
#   normal

# smell:
#   server is empty

# cleanup:
#   stop server after 10 minutes of emptiness

class EmptyServer < Stain
  def clean
    no_longer_empty_server_ids.each do |server_id|
      forget server_id
    end

    currently_empty_servers.each do |stain, server|
      if stain.duration > 10 * 60
        if pinky = pinkies.find {|p| p.server_ids.include?(server.id) }
          log.warn event: 'server_empty',
            pinky: pinky.id,
            server: stain.id,
            action: 'shutting down'

          @pinkies.stop_server! pinky.id, server.id
          forget server.id
        end

      elsif stain.duration > 2 * 60
        log.info event: 'server_empty',
          id: stain.id,
          duration: stain.duration
      end
    end

    new_empty_servers.each do |server|
      notice server.id
    end
  end

  def new_empty_servers
    (empty_servers.ids - noticed.ids).map do |server_id|
      @servers.find_id(server_id)
    end
  end

  def currently_empty_servers
    noticed.map do |stain|
      [stain, @servers.find_id(stain.id)]
    end
  end

  def no_longer_empty_server_ids
    (noticed.ids - empty_servers.ids)
  end

  def empty_servers
    @servers.select{|s| s.players.size == 0 }
  end

  def noticed
    @stains_cache.in_state(:server_empty)
  end

  def notice id
    @stains_cache << EntityStateChange.new(
      id,
      :server_empty,
      Time.now
    )
  end

  def forget id
    @stains_cache.delete(id)
  end
end