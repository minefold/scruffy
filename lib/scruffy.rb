require "core_ext"
require "scruffy/logger"
require "scruffy/entity_collection"
require "scruffy/box_type"
require "scruffy/box"
require "scruffy/boxes"
require "scruffy/fog_cluster"
require "scruffy/local_cluster"
require "scruffy/redis_bus"
require "scruffy/pinkies"
require "scruffy/pinky"
require "scruffy/server"
require "scruffy/entity_state_cache"
require "scruffy/stains"
require "scruffy/allocator"

class Scruffy
  attr_reader :log

  def initialize bus, boxes, pinkies
    @bus = bus
    @boxes = boxes
    @pinkies = pinkies

    @log = Logger.new
  end

  def sweep!
    # load previous scruffy caches
    @boxes_cache = EntityStateCache.deserialize(@bus.boxes_cache) || []
    @pinkies_cache = EntityStateCache.deserialize(@bus.pinkies_cache) || []

    @boxes.update!
    @pinkies.update!

    update_states
    find_and_clean_stains
    update_caches
  end

  def update_states
    find_gone_boxes
    find_new_boxes

    find_gone_pinkies
    find_new_pinkies

    start_boxes
    stop_boxes
  end

  def find_gone_boxes
    (@boxes_cache.ids - @boxes.ids).each do |box_id|
      log.info event: 'box_gone', id: box_id

      @bus.del_box_info(box_id)
    end
  end

  def find_new_boxes
    (@boxes.ids - @boxes_cache.ids).each do |box_id|
      box = @boxes.by_id(box_id)
      log.info event: 'box_found', id: box_id,
        ip: box.ip, type: box.type.id, state: box.state,
        started_at: box.started_at, tags: box.tags

      @bus.store_box_info(box.id, box.ip, box.type.id, box.started_at, box.tags)
    end
  end

  def find_gone_pinkies
    (@boxes_cache.ids - @boxes.ids).each do |box_id|
      if pinky = @pinkies.by_id(box_id)
        if pinky.stopping?
          log.info event: 'box_gone', id: box_id, action: 'removing pinky'
          @pinkies.delete! box_id
        end
      end
    end
  end

  def find_new_pinkies
    (@boxes.up.ids - @pinkies.ids).each do |box_id|
      log.info event: 'box_up', id: box_id, action: 'set pinky to starting'

      @pinkies.pinky_starting! box_id
    end
  end

  def start_boxes
    allocator = Allocator.new(@boxes, @pinkies)

    if allocator.low_capacity?
      log.warn event: 'low_capacity',
        used: allocator.server_slots_used,
        available: allocator.server_slots_available,
        action: 'starting new box'

      @boxes.start_new BoxType.find('c1.xlarge')
    end
  end

  def stop_boxes
    allocator = Allocator.new(@boxes, @pinkies)

    allocator.excess_pinkies.each do |pinky|
      log.warn event: 'excess_capacity',
        id: pinky.id,
        used: allocator.server_slots_used,
        available: allocator.server_slots_available,
        action: 'terminating box'

      @pinkies.pinky_stopping! pinky.id
      @boxes.terminate pinky.id
    end
  end

  def find_and_clean_stains
    Stain.all.each do |klass|
      stain = klass.new(@bus, @boxes_cache, @pinkies_cache, @stains_cache, @boxes, @pinkies)
      stain.clean
    end
  end

  def update_caches
    @boxes_cache.diff! 'box', @boxes
    @bus.store_boxes_cache @boxes_cache.serialize

    @pinkies_cache.diff! 'pinky', @pinkies
    @bus.store_pinkies_cache @pinkies_cache.serialize
  end

  def report
    log = Logger.new(event: 'sweep')
    @boxes.each do |box|
      log.info event: :box,
        id: box.id,
        ip: box.ip,
        type: box.type.id,
        state: box.state,
        uptime: box.uptime_mins,
        tags: box.tags
    end

    @pinkies.each do |pinky|
      log.info event: :pinky,
        id: pinky.id,
        state: pinky.state

      pinky.servers.each do |server|
        log.info server_id: server.id, state: server.state
      end
    end
    server_count = @pinkies.inject(0){|i, pinky| i + pinky.servers.count }
    log.info event: :summary,
      boxes: @boxes.count,
      pinkies: @pinkies.count,
      servers: server_count
  end
end
