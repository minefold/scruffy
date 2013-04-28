# causes:
#   funpack stalled

# smell:
#   up servers with missing heartbeats

# cleanup:

# report:

class ServerHeartbeatMissing < Stain
  include StainWatcher

  stain :server_heartbeat_missing

  def affected_ids
    @servers.up.reject(&:heartbeat).ids
  end

  def check_stain(stain)
    if stain.duration > 10 * 60
      log.out 'error',
        event: stain_type,
        server_id: stain.id,
        duration: stain.duration,
        action: 'kill frozen server'

      if pinky = pinkies.find {|p| p.server_ids.include?(stain.id) }
        @pinkies.stop_server! pinky.id, stain.id
      end

    elsif stain.duration > 1 * 60
      log.warn event: stain_type, server_id: stain.id,
        duration: stain.duration
    end
  end
end