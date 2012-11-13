# severity:
#   minor

# causes:
#   manual intervention

# smell:
#   box stopping with up pinky

# cleanup:
#   set pinky to stopping

# report:

class EmptyBoxStopping < Stain
  def clean
    (pinkies.up.ids & boxes.stopping.ids).each do |pinky_id|
      log.warn event: 'empty_box_stopping',
        id: pinky_id,
        action: 'pinky state => down'
      
      pinkies.pinky_stopping! pinky_id
    end
  end

end