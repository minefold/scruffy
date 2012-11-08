# causes:
#   crash bug in pinky causing a restart loop
#   network between pinky and the rest of the system down
#   connection between redis and pinky fails
#   pinky ran out of memory/swap space
#   pinky ran out of disk space to write pid files

# smell:
#   there are running boxes with up state that don't have
#   associated pinky heartbeats

# cleanup:
#   set relevent pinky state to down
#   wait 1 minute for the heartbeat to come on line
#   if it doesn't come back online
#     mark servers as down
#     kick players
#     alert pagerduty (we should try and fix this manually)

# report:
#    worlds affected (potential data loss)
#    players affected

class MissingPinky < Stain
  def clean
    (up_box_ids - pinkies.ids).each do |missing_pinky_id|
      entry = boxes_cache.find{|entry|
        entry.id == missing_pinky_id && entry.state == 'missing_pinky'
      }

      if !entry
        box = boxes.by_id(missing_pinky_id)
        entry = BoxCacheEntry.new(box.id, 'missing_pinky', Time.now)
        boxes_cache << entry
      end

      duration = Time.now - entry.transitioned_at

      log.warn event: 'missing_pinky',
        id: missing_pinky_id,
        duration: duration
    end
  end

  def up_box_ids
    boxes.select{|b| b.state == :up}.map{|b| b.id }
  end
end