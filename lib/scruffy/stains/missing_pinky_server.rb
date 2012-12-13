# causes:
#   unknown

# smell:
#   server state key without a pinky server key
#   eg. /server/state/1234 + pinky/1/heartbeat without a /pinky/1/1234

# cleanup:
# pinky must have shut the server down. Remove keys

# report:

class MissingPinkyServer < Stain
  include StainWatcher

  stain :missing_pinky_server

  def affected_ids
    # server state without pinky server info
    @servers.ids - @pinkies.server_ids
  end

  def stain_gone(stain_id)
    log.warn event: 'missing_pinky_server_no_longer_missing', id: stain_id
  end

  def check_stain(stain)
    if stain.duration > 1 * 60
      log.warn event: stain_type,
        id: stain.id,
        action: 'removing_keys'

      @servers.del_server_info(stain.id)

    else
      log.info event: stain_type,
        id: stain.id,
        duration: stain.duration
    end
  end
end