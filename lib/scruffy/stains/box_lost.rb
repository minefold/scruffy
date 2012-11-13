# severity: major

# causes:
#   EC2 terminated instance

# smell:
#   there's a box in the cache that's not in EC2

# cleanup:
#   clean up associated state
#   kick players

# report:
#    worlds affected (potential data loss)
#    players affected

class BoxLost < Stain  
  def clean
    lost_boxes.each do |lost_box_id|
      log.warn event: 'lost_box', id: lost_box_id, action: 'cleaning up'

      boxes_cache.delete(lost_box_id)
    end
  end
  
  def lost_boxes
    boxes_cache.ids - boxes.ids
  end
end