require "core_ext"
require "scruffy/logger"
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
    @stains_cache = EntityStateCache.deserialize(@bus.stains_cache) || []

    @boxes.update!
    @pinkies.update!

    find_and_clean_stains

    @bus.store_boxes_cache @boxes_cache.serialize
    @bus.store_stains_cache @stains_cache.serialize
  end

  def find_and_clean_stains
    Stain.all.each do |klass|
      stain = klass.new(@bus, @boxes_cache, @pinkies_cache, @stains_cache, @boxes, @pinkies)
      stain.clean
    end
  end

  def report
    log = Logger.new(event: 'sweep')
    @boxes.each do |box|
      log.info event: :box,
        id: box.id,
        ip: box.ip,
        type: box.type.id,
        state: box.state,
        started_at: box.started_at,
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
