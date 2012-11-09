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
    detect_new
    monitor_existing
  end

  def detect_new
    (up_box_ids - pinkies.ids - current_stain_ids).each do |missing_pinky_id|
      box = boxes.by_id(missing_pinky_id)

      entry = EntityStateChange.new(box.id, 'missing_pinky', Time.now)
      stains_cache << entry

      pinkies.pinky_down! box.id

      log.warn event: 'missing_pinky_found',
        id: missing_pinky_id,
        action: 'pinky state => down'
    end
  end

  def monitor_existing
    current_stains.select{|stain| stain.duration > 60 }.each do |stain|

    end
  end

  def up_box_ids
    boxes.select{|b| b.state == :up}.map{|b| b.id }
  end

  def current_stain_ids
    current_stains.map{|stain| stain.id }
  end

  def current_stains
    stains_cache.select{|stain| stain.state == 'missing_pinky' }
  end
end