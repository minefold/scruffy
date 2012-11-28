# TODO this logic belongs in Minefold not Party Cloud

# severity:
#   normal

# smell:
#   server is empty

# cleanup:
#   stop server after 1 minute of emptiness

class EmptySharedServer < Stain
  EMPTY_DURATION = 1 * 60

  def server_players connected_players, server_id
    connected_players.inject([]) do |p, (player_id, player_server_id)|
      p << player_id if player_server_id == server_id
    end
  end

  def clean
    shared_server_ids = @bus.shared_server_ids
    connected_players = @bus.connected_players
    
    (shared_server_ids - @pinkies.server_ids).each do |server_id|
      log.info event: 'shared_server_shutdown',
        server: server_id
      
      @bus.del_shared_server(server_id)
    end

    @pinkies.each do |pinky|
      (pinky.server_ids & shared_server_ids).each do |server_id|
        if (server_players(connected_players, server_id) || 0).size > 0
          remove_stain(server_id, :shared_server_empty)
          remove_stain(server_id, :shared_server_empty_stopping)

        else
          if stain = find_stain(server_id, :shared_server_empty_stopping)
            log.info event: 'empty_server_stopping',
              pinky: pinky.id,
              server: server_id,
              duration: stain.duration
          else
            stain = find_stain(server_id, :shared_server_empty) ||
                    add_stain(server_id, :shared_server_empty)

            if stain.duration < EMPTY_DURATION
              log.info event: 'empty_server',
                pinky: pinky.id,
                server: server_id,
                duration: stain.duration

            else
              log.info event: 'empty_server',
                pinky: pinky.id,
                server: server_id,
                duration: stain.duration,
                action: 'stopping'

              stains_cache.delete(stain.id)
              add_stain(server_id, :shared_server_empty_stopping)
              @pinkies.stop_server! pinky.id, server_id
            end
          end
        end
      end
    end

    current_stains = stains_cache.in_state(:shared_server_empty) +
                     stains_cache.in_state(:shared_server_empty_stopping)

    (current_stains.ids - @pinkies.server_ids).each do |stain_id|
      log.info event: 'empty_server_gone', server: stain_id
      stains_cache.delete(stain_id)
    end
  end

  def find_stain(id, state)
    stains_cache.find{|s| s.id == id && s.state == state }
  end

  def empty_stains
    stains_cache.in_state(:shared_server_empty)
  end

  def empty_stopping_stains
    stains_cache.in_state(:shared_server_empty_stopping)
  end

  def add_stain(id, state)
    stain = EntityStateChange.new(id, state, Time.now)
    stains_cache << stain
    stain
  end

  def remove_stain(id, state)
    stains_cache.delete_if{|entry| entry.id == id && entry.state == state}
  end
end