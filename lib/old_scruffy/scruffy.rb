require 'core_ext'
require 'bytes'

module Scruffy
  class Scruffy
    include Logging

    attr_reader :redis_universe,
                :boxes, :running_boxes, :working_boxes, :broken_boxes,
                :running_worlds

    def redis; Prism.redis; end

    def perform_sweep *a, &b
      @sweep_op = EM::Callback *a, &b
      RedisUniverse.collect do |universe|
        @redis_universe = universe
        Box.all method(:query_boxes)
      end
      @sweep_op
    end

    def query_boxes boxes
      @boxes = boxes

      @running_boxes, @working_boxes, @broken_boxes, @running_worlds = [], [], [], {}
      @duplicate_worlds = {}
      
      EM::Iterator.new(boxes, 10).each(proc{ |box,box_iter|
        box.query_aws_state do |aws_state|
          if aws_state == 'running'
            @running_boxes << box
            started_world_sweep = Time.now
            
            # found a running box in aws, what's its state?
            if heartbeat = @redis_universe.pinkies[box.pinky_id]
              @working_boxes << box
            else
              @broken_boxes << box
            end
            box_iter.next
            
            
            # op = box.query_worlds
            #             op.callback do |worlds|
            #               StatsD.measure_timer started_world_sweep, "scruffy.worlds"
            #       
            #               @working_boxes << box
            #               duplicate_world_ids = (@running_worlds.keys & worlds.keys)
            #               duplicate_world_ids.each do |world_id|
            #                 @duplicate_worlds[world_id] ||= []
            #                 @duplicate_worlds[world_id].push @running_worlds[world_id], worlds[world_id]
            #               end
            #               
            #               @running_worlds.merge! worlds
            # end
            # op.errback do
            #   @broken_boxes << box
            #   box_iter.next
            # end
          elsif aws_state.nil?
            @broken_boxes << box
            box_iter.next
          else
            box_iter.next
          end
        end
      }, method(:update_state))
    end

    def update_state
      RedisUniverse.collect do |universe|
        @redis_universe = universe
        @allocator = WorldAllocator.new(universe, @running_boxes)
        @allocator.rebalance

        clear_phantoms
        stop_duplicates

        update_boxes
        lost_boxes
        lost_busy_boxes

        found_worlds
        lost_worlds
        lost_busy_worlds

        fix_broken_boxes

        shutdown_idle_worlds
        rebalance_worlds

        @sweep_op.call
      end
    end

    def clear_phantoms
      redis.keys("worlds:allocation_difference:*") do |keys|
        keys.each do |key|
          redis.del key unless world_running?(key.split(':').last)
        end
      end
    end
    
    def stop_duplicates
      @duplicate_worlds.each do |world_id, worlds|
        debug "duplicate world detected world_id=#{world_id} #{worlds}"
        latest_dupe = worlds.sort_by{|w| w['started_at'] }.last
        debug "stopping latest dupe:#{latest_dupe}"
        redis.lpush "workers:#{latest_dupe['pinky_id']}:worlds:requests:stop", world_id
      end
    end

    def update_boxes
      running_boxes.each do |box|
        debug "found box:#{box.pinky_id}" unless redis_universe.boxes[:running].keys.include? box.pinky_id
        redis.store_running_box box
      end
    end

    def lost_boxes
      lost_box_ids = redis_universe.boxes[:running].keys - running_boxes.map(&:pinky_id)
      lost_box_ids.each do |pinky_id|
        debug "lost box:#{pinky_id}"
        host = redis_universe.boxes[:running][pinky_id]['host']
        redis.unstore_running_box pinky_id, host
      end
    end

    def lost_busy_boxes
      lost_busy_box_ids = redis_universe.boxes[:busy].keys - running_boxes.map(&:pinky_id)
      lost_busy_box_ids.each do |pinky_id|
        busy_hash = redis_universe.boxes[:busy][pinky_id]
        busy_length = Time.now - Time.at(busy_hash['at'])
        if busy_length > busy_hash['expires_after']
          debug "lost busy box:#{pinky_id}"
          redis.hdel "workers:busy", pinky_id
        else
          debug "busy box:#{pinky_id} (#{busy_hash['state']} #{busy_length} seconds)"
        end
      end
    end

    def found_worlds
      new_worlds = running_worlds.reject{|world_id, world| redis_universe.worlds[:running].keys.include? world_id };

      new_worlds.each do |world_id, world|
        debug "found world:#{world_id} #{world}"

        heartbeat = redis_universe.widget_worlds[world_id]
        # TODO: this should always be present but its not getting it from the heartbeat
        if heartbeat
          redis.store_running_world world_id, heartbeat['pinky_id'], heartbeat['host'], heartbeat['port'], heartbeat['slots']
        end
      end
    end

    def lost_worlds
      redis.keys('worlds:lost:*') do |lost_keys|
        running_world_ids = redis_universe.worlds[:running].keys & running_worlds.keys
        lost_world_ids = lost_keys.map{|key| key.split(':').last }
        
        (lost_world_ids & running_world_ids).each do |world_id|
          debug "found lost world:#{world_id}"
          redis.del "worlds:lost:#{world_id}"
        end
      end
      
      lost_world_ids = redis_universe.worlds[:running].keys - running_worlds.keys
      lost_world_ids.each do |world_id|
        notice("worlds:lost:#{world_id}", true) do |since, _|
          pinky_id = redis_universe.worlds[:running][world_id]['pinky_id']
          lost_for = (Time.now - since)
          
          if lost_for < 120
            debug "missing world:#{world_id} instance:#{pinky_id} (#{lost_for} seconds)"
            
          else
            debug "lost world:#{world_id} instance:#{pinky_id}"
            Exceptional.rescue { raise "lost world: #{world_id} instance:#{pinky_id}" }
            
            redis.unstore_running_world pinky_id, world_id
            redis.del "worlds:lost:#{world_id}"
          end
        end
      end
    end

    def lost_busy_worlds
      lost_busy_world_ids = redis_universe.worlds[:busy].keys - running_worlds.keys
      lost_busy_world_ids.each do |world_id|
        busy_hash = redis_universe.worlds[:busy][world_id]
        busy_length = Time.now - Time.at(busy_hash['at'])
        if busy_length > busy_hash['expires_after']
          debug "lost busy world:#{world_id}"
          redis.hdel "worlds:busy", world_id
        else
          debug "lost busy world:#{world_id} (#{busy_hash['state']} #{busy_length} seconds)"
        end
      end
    end

    def fix_broken_boxes
      broken_boxes.each do |box|
        debug "ignoring broken box:#{box.pinky_id}"
      end
    end

    def shutdown_idle_worlds
      # if any worlds previously declared as empty have become unempty, clear busy state
      running_worlds = redis_universe.worlds[:running]
      running_worlds.select {|world_id, world| world[:players].any? }.each do |world_id, world|
        if busy_hash = redis_universe.worlds[:busy][world_id]
          redis.hdel 'worlds:busy', world_id if busy_hash['state'] == 'empty'
        end
      end

      running_worlds.select {|world_id, world| world[:players].empty? }.each do |world_id, world|
        if busy_hash = redis_universe.worlds[:busy][world_id]
          busy_length = Time.now - Time.at(busy_hash['at'])
          debug "busy world:#{world_id} (#{busy_hash['state']} #{busy_length} seconds)"

          if busy_length > busy_hash['expires_after']
            debug "box:#{world['pinky_id']} world:#{world_id} stopping empty world"
            redis.lpush "workers:#{world['pinky_id']}:worlds:requests:stop", world_id
          end
        else
          debug "box:#{world['pinky_id']} world:#{world_id} is empty"
          redis.set_busy "worlds:busy", world_id, 'empty', expires_after: 60
        end
      end
    end

    def world_running? world_id
      redis_universe.worlds[:running].keys.include? world_id
    end

    def rebalance_worlds
      @allocator.world_allocations.each do |a|
        op = redis.get("worlds:#{a[:world_id]}:moving")
        op.callback do |move_started_at|
          if move_started_at
            if world_running? a[:world_id]
              redis.del "worlds:#{a[:world_id]}:moving"
            else
              debug "world:#{a[:world_id]} is moving (#{Time.now - Time.at(move_started_at)} seconds)"
            end

          elsif a[:current_world_slots] == a[:required_world_slots]
            ignore "worlds:allocation_difference:#{a[:world_id]}"

          else
            notice("worlds:allocation_difference:#{a[:world_id]}", a[:required_world_slots]) do |since, slots|
              under_allocated = a[:current_world_slots] < a[:required_world_slots]
              minutes = (Time.now - since) / 60.0
              debug "world:#{a[:world_id]} #{a[:current_world_slots]} <-> #{a[:required_world_slots]} (steps:#{a[:step_difference]}) #{under_allocated ? "under" : "over"} allocated for #{minutes} minutes"
              debug "#{a.inspect}"
              over_allocated = !under_allocated

              rebalance_now = false
              if under_allocated
                # we should move world up if we've been under for 5 minutes or
                # we're more than 1 step from balanced
                rebalance_now = minutes > 5 || a[:step_difference] > 1
              else
                # we should move world down if we've been over for 20 minutes and
                # we're more than 2 steps from balanced
                rebalance_now = minutes > 20 && a[:step_difference] < -2
              end

              if rebalance_now
                World.update(
                  {_id: BSON::ObjectId(a[:world_id])},
                  { '$set' => {'allocation_slots' => a[:required_player_slots] }}
                )

                debug "reallocating world to player_slots:#{a[:required_player_slots]}"
                redis.lpush_hash 'worlds:move_request',
                  world_id: a[:world_id],
                  player_slots: a[:required_player_slots]
              end
            end
          end
        end
      end
    end

    def notice key, value, *a, &b
      cb = EM::Callback *a, &b

      op = redis.get_json(key) 
      op.callback do |h|
        if h and h['value'] == value
          cb.call Time.at(h['at']), h['value']
        else
          redis.set(key, { at: Time.now.to_i, value: value }.to_json)
        end
      end

      cb
    end

    def ignore key
      redis.del key
    end

    def record_stats
      running_boxes = redis_universe.boxes[:running]
      StatsD.gauge "boxes.count", running_boxes.size
      StatsD.gauge "players.count", redis_universe.players.size
      StatsD.gauge "worlds.count",  redis_universe.worlds[:running].size
    end

  end
end