# severity: minor

# causes:
#   box manually created

# smell:
#   new box that isn't in scruffy's cache

# cleanup:
#   add to cache

class BoxFound < Stain  
  def clean
    (boxes.ids - boxes_cache.ids).each do |new_box_id|
      log.info event: 'box_found', id: new_box_id, action: 'adding to cache'

      box = boxes.by_id(new_box_id)
      boxes_cache << EntityStateChange.new(box.id, box.state, box.started_at)
    end
  end
end