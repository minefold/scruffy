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
    if stain.duration > 1 * 60
      log.warn event: stain_type, server_id: stain.id,
        duration: stain.duration
    end
  end
end