# causes:
#   crash bug in pinky causing a restart loop
#   network between pinky and the rest of the system down
#   connection between redis and pinky fails
#   pinky ran out of memory/swap space
#   pinky ran out of disk space to write pid files

# smell:
#   there are running servers with up state that don't have 
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

class MissingPinky
  attr_reader :log
  
  def initialize boxes, pinkies
    @boxes, @pinkies = boxes, pinkies
    
    @log = Logger.new(event: 'missing_pinky')
  end
  
  def smell?
    missing_pinky_ids = @boxes.ids - @pinkies.ids
    missing_pinky_ids.each do |id|
      box = @boxes.find{|b| b.id == id }
      log.info(box_id: box.id)
    end
  end
  
  def up_servers
    
  end
end