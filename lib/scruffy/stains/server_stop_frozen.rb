# causes:
#   pinky failing to back up to s3

# smell:
#   server in shutdown state longer than 5 minutes

# cleanup:
#   tell pinky to shutdown server

# report:
#    worlds affected (potential data loss)
#    players affected

class ServerStopFrozen < Stain
  include StainWatcher

  stain :server_stop_frozen

  def affected_ids
    @servers.in_state('stopping').ids
  end

  def check_stain(stain)
    if stain.duration > 1 * 60
      log.warn event: stain_type, server_id: stain.id

    elsif stain.duration > 5 * 60
      log.warn event: stain_type, server_id: stain.id, action: 'stopping'

      if pinky = @pinkies.find_by_server_id(stain.id)
        # @servers.set_server_state(stain.id, 'up')
        # @pinkies.stop_server! pinky.id, stain.id
      end
    end
  end
end