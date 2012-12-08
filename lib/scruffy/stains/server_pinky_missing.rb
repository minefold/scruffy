# causes:
#   server not shutdown cleanly

# smell:
#   server keys for non existant pinky

# cleanup:
#   remove keys

# report:
#    worlds affected (potential data loss)
#    players affected

class ServerPinkyMissing < Stain
  include StainWatcher

  stain :server_pinky_missing

  def affected_ids
    # pinky servers without pinky state
    @pinkies.select{|s| s.state.nil? }.inject([]) do |a, p|
      a + p.server_ids
    end
  end

  def check_stain(stain)
    if stain.duration > 5 * 60
      log.warn event: stain_type, id: stain.id, action: 'removing keys'

      @bus.del_server_keys(stain.id)
      if pinky = @pinkies.find{|p| p.server_ids.include?(stain.id) }
        @bus.del_pinky_server(pinky.id, stain.id)
      end

    else
      log.info event: stain_type, id: stain.id, duration: stain.duration
    end
  end
end