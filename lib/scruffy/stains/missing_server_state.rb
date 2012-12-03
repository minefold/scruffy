# causes:
#   human error

# smell:
#   pinky server key without a server state key
#   eg. /pinky/1/1234 without a /server/state/1234

# cleanup:
#   tell pinky to shutdown server

# report:
#    worlds affected (potential data loss)
#    players affected

class MissingServerState < Stain
  def clean
    new_stain_ids.each do |stain_id|
      notice stain_id
    end

    no_longer_stains.each do |stain_id|
      log.warn event: 'server_state_no_longer_missing', id: stain_id
      forget stain_id
    end

    current_stains.each do |stain|
      if stain.duration > 1 * 60
        log.warn event: 'missing_server_state',
          id: stain.id,
          action: 'stopping'

        if pinky = @pinkies.find {|p| p.server_ids.include?(stain.id) }
          # @pinkies.stop_server! pinky.id, stain.id
          # forget stain.id
        end

      else
        log.info event: 'missing_server_state',
          id: stain.id,
          duration: stain.duration
      end
    end
  end

  def affected_server_ids
    @pinkies.server_ids - @servers.ids
  end

  def new_stain_ids
    affected_server_ids - current_stains.ids
  end

  def no_longer_stains
    current_stains.ids - affected_server_ids
  end

  def current_stains
    @stains_cache.in_state(:missing_server_state)
  end

  def notice id
    @stains_cache << EntityStateChange.new(
      id,
      :missing_server_state,
      Time.now
    )
  end

  def forget id
    @stains_cache.delete(id)
  end
end