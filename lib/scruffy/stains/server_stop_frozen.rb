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
    pinky = @pinkies.find_by_server_id(stain.id)
    data = {
      event: stain_type,
      server: stain.id,
      duration: stain.duration
    }
    data[:pinky] = pinky.id if pinky

    if stain.duration > 5 * 60
      log.warn data.merge(action: 'removing_keys')

      @servers.del_server_info(stain.id)

    elsif stain.duration > 4 * 60
      log.warn data.merge(action: 'killing_server')

      if pinky
        @pinkies.stop_server! pinky.id, stain.id
      end

    elsif stain.duration > 1 * 60
      log.warn data
    end
  end
end