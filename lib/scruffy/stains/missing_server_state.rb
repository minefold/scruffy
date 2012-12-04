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
  include StainWatcher

  stain :missing_server_state

  def affected_ids
    # pinky server info without server info
    @pinkies.server_ids - @servers.ids
  end

  def stain_gone(stain_id)
    log.warn event: 'server_state_no_longer_missing', id: stain_id
  end

  def check_stain(stain)
    if stain.duration > 1 * 60
      log.warn event: stain_type,
        id: stain.id,
        action: 'stopping'

      if pinky = @pinkies.find {|p| p.server_ids.include?(stain.id) }
        @pinkies.stop_server! pinky.id, stain.id
      end

    else
      log.info event: stain_type,
        id: stain.id,
        duration: stain.duration
    end
  end
end