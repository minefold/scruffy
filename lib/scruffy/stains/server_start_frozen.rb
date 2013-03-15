# causes:
#   unknown

# smell:
#   server in starting state longer than 5 minutes

# cleanup:

# report:
#    worlds affected
#    players affected

class ServerStartFrozen < Stain
  include StainWatcher

  stain :server_start_frozen

  def affected_ids
    @servers.starting.ids
  end

  def check_stain(stain)
    if stain.duration > 5 * 60
      server = @servers.up.find{|s| s.players.include?(stain.id) }
      log.warn event: 'server_start_frozen',
        server: stain.id,
        action: 'killing',
        duration: stain.duration

    if stain.duration > 1 * 60
      log.info event: stain_type,
        server: stain.id,
        duration: stain.duration
    end
  end
end