# TODO this logic belongs in Minefold not Party Cloud

# severity:
#   normal

# smell:
#   server is empty

# cleanup:
#   stop server after 1 minute of emptiness

class EmptySharedServer < Stain
  include StainWatcher

  stain :empty_shared_server

  def affected_ids
    (@servers.in_state('up').ids & bus.shared_server_ids).select do |id|
      @servers.find_id(id).players.size == 0
    end
  end

  def stain_noticed(stain_id)
    log.warn event: 'shared_server_empty', id: stain_id
  end

  def stain_gone(stain_id)
    log.warn event: 'server_no_longer_empty', server_id: stain_id
  end

  def check_stain(stain)
    if stain.duration > 1 * 60
      if pinky = pinkies.find {|p| p.server_ids.include?(stain.id) }
        log.warn event: 'shared_server_empty',
          server: stain.id,
          pinky: pinky.id,
          action: 'shutting down'

        @pinkies.stop_server! pinky.id, stain.id
      end

    else
      log.info event: 'shared_server_empty',
        id: stain.id,
        duration: stain.duration
    end
  end
end