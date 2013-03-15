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
    if stain.duration < 5 * 60
      log.warn event: stain_type, 
        server: stain.id,
        duration: stain.duration
    else
      server = @servers.up.find{|s| s.players.include?(stain.id) }
      log.warn event: 'server_start_frozen',
        id: stain.id,
        action: 'killing'
    end
  end
end