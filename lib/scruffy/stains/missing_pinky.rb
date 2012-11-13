# causes:
#   crash bug in pinky causing a restart loop
#   network between pinky and the rest of the system down
#   connection between redis and pinky fails
#   pinky ran out of memory/swap space
#   pinky ran out of disk space to write pid files

# smell:
#   pinkies in up state that previously had a heartbeat and now don't

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
    # missing_pinky_ids.each do |missing_pinky_id|
    #   box = boxes.by_id(missing_pinky_id)
    # 
    #   pinkies.pinky_down! box.id
    # 
    #   log.warn event: 'missing_pinky_found',
    #     id: missing_pinky_id,
    #     action: 'pinky state => down'
    # end
  end

  def missing_pinky_ids
    up_pinky_ids - heartbeat_ids
  end
  
  def heartbeat_ids
    pinkies.heartbeats.map{|hb| hb[:id] }
  end
  
  def up_pinky_ids
    pinkies.states.select{|ps| ps[:state] == :up }.map{|ps| ps[:id] }
  end
end