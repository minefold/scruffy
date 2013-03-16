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
    if stain.duration > 10 * 60
      log.warn event: 'server_start_frozen',
        server: stain.id,
        action: 'killing',
        duration: stain.duration
        
      @bus.del_server_keys(stain.id)

    elsif stain.duration > 1 * 60
      log.info event: stain_type,
        server: stain.id,
        duration: stain.duration
    end
  end
end