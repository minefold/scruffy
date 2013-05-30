# causes:
#   unknown

# smell:
#   minecraft player in an up server that's not in prism

# cleanup:
#   remove player from server

# This is temporary while I chase down the cause

class PrismPlayerMissing < Stain
  include StainWatcher

  stain :prism_player_missing

  def up_non_tf2_servers
    @servers.up.select{|s| s.funpack != '50bec3967aae5797c0000004' }
  end

  def affected_ids
    @affected_ids ||= begin
      up_non_tf2_servers.map(&:players).flatten.uniq - @bus.prism_players
    end
  end

  def check_stain(stain)
    if stain.duration < 1 * 60
      log.warn event: stain_type, player: stain.id,
        duration: stain.duration
    else
      server = up_non_tf2_servers.find{|s| s.players.include?(stain.id) }
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