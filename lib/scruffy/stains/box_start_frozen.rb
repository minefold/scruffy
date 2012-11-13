# causes:
#   ec2 request stalls or fails
#   ec2 instance starts without tags

# smell:
#   box in starting state for longer than 5 minutes

# cleanup:
#   terminate instance

# report:
#   instance affected

class BoxStartFrozen < Stain
  FROZEN_DURATION = 5 * 60

  def clean
    frozen_box_entries.each do |entry|
      log.warn event: 'box_start_frozen',
        id: entry.id,
        action: 'terminating',
        duration: entry.duration

      boxes.terminate entry.id
    end
  end

  def frozen_box_entries
    boxes_cache.starting.select{|entry| entry.duration > FROZEN_DURATION }
  end
end