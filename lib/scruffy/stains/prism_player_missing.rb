# causes:
#   unknown

# smell:
#   there's a player in the servers thats not in prism

# cleanup:
#   remove player from server

# This is temporary while I chase down the cause

class PrismPlayerMissing < Stain
  include StainWatcher

  stain :prism_player_missing

  def affected_ids
    @affected_ids ||= begin
      prism_players = @bus.redis.smembers('prism:i-e995cf96:players')
      @servers.players - prism_players
    end
  end

  def check_stain(stain)
    if stain.duration < 1 * 60
      log.warn event: stain_type, player: stain.id,
        duration: stain.duration
    else
      server = @servers.find{|s| s.players.include?(stain.id) }
      if server
        log.warn event: stain_type,
          player: stain.id,
          server: server.id,
          action: 'removing',
          duration: stain.duration
        # @bus.redis.srem("server:#{server.id}:players", stain.id)
      else
        log.warn event: stain_type, player: stain.id, server: 'unknown'
      end
    end
  end
end