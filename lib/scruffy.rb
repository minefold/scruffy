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

  def initialize bus, boxes, pinkies, servers
    @bus = bus
    @boxes = boxes
    @pinkies = pinkies
    @servers = servers

    @log = Mutli::Logger.new
  end

  def sweep!
    # load previous scruffy caches
    @boxes_cache = EntityStateCache.deserialize(@bus.cache(:boxes)) || []
    @pinkies_cache = EntityStateCache.deserialize(@bus.cache(:pinkies)) || []
    @servers_cache = EntityStateCache.deserialize(@bus.cache(:servers)) || []
    @stains_cache = EntityStateCache.deserialize(@bus.cache(:stains)) || []

    @boxes.update!
    @pinkies.update!
    @servers.update!

    update_states
    find_and_clean_stains
    update_caches
  end

  def update_states
    find_gone_boxes
    find_new_boxes

    find_gone_pinkies
    find_new_pinkies

    find_gone_servers
    find_new_servers

    start_boxes
    stop_boxes
  end

  def find_gone_boxes
    (@boxes_cache.ids - @boxes.ids).each do |box_id|
      log.info event: 'box_gone', id: box_id

      @bus.del_box_info(box_id)
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
        if pinky.stopping? or pinky.down?
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

  def find_gone_servers
    (@boxes_cache.ids - @boxes.ids).each do |box_id|
      if pinky = @pinkies.by_id(box_id)
        if pinky.stopping? or pinky.down?
          log.info event: 'box_gone', id: box_id, action: 'removing pinky'
          @pinkies.delete! box_id
        end
      end
    end
  end

  def find_new_servers
    (@boxes.up.ids - @pinkies.ids).each do |box_id|
      log.info event: 'box_up', id: box_id, action: 'set pinky to starting'

      @pinkies.pinky_starting! box_id
    end
  end

  def start_boxes
    allocator = Allocator.new(@boxes, @pinkies, @servers)

    if allocator.low_capacity?
      box_type = allocator.new_box_type

      log.warn event: 'low_capacity',
        used: allocator.used_server_slots,
        available: allocator.total_server_slots,
        action: 'starting new box',
        type: box_type.id

      box_id = @boxes.start_new allocator.new_box_type

      log.info event: 'box_created',
        id: box_id
    end
  end

  def stop_boxes
    allocator = Allocator.new(@boxes, @pinkies, @servers)

    allocator.excess_pinkies.each do |pinky|
      log.warn event: 'excess_capacity',
        id: pinky.id,
        used: allocator.used_server_slots,
        available: allocator.total_server_slots,
        action: 'terminating box'

      # @pinkies.pinky_stopping! pinky.id
      # @boxes.terminate pinky.id
    end
  end

  def find_and_clean_stains
    Stain.all.each do |klass|
      stain = klass.new(@bus, @boxes_cache, @pinkies_cache, @stains_cache, @boxes, @pinkies, @servers)
      stain.clean
    end
  end

  def update_caches
    @boxes_cache.diff! 'box', @boxes
    @bus.store_cache :boxes, @boxes_cache.serialize

    @pinkies_cache.diff! 'pinky', @pinkies
    @bus.store_cache :pinkies, @pinkies_cache.serialize

    @bus.store_cache :servers, @servers_cache.serialize

    @bus.store_cache :stains, @stains_cache.serialize
  end

  def report
    log = Mutli::Logger.new(event: 'sweep')
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
        state: pinky.state,
        ram_free: pinky.free_ram_mb,
        disk_free: pinky.free_disk_mb,
        cpu_idle: pinky.idle_cpu

      # pinky.servers.each do |server|
      #   log.info event: 'server',
      #     server: server.id,
      #     state: server.state,
      #     port: server.port,
      #     pinky: pinky.id
      # end
    end

    allocator = Allocator.new(@boxes, @pinkies, @servers)

    log.info event: :summary,
      boxes: @boxes.count,
      pinkies: @pinkies.count,
      players: @servers.players.size,
      slots_total: allocator.total_server_slots,
      slots_used: allocator.used_server_slots,
      slots_available: allocator.available_server_slots
  end

  def record_metrics
    if $metrics
      $metrics.add 'players.count' => {
        :type => :gauge,
        :value => @servers.players.size,
        :source => 'party-cloud'
      }
      
      $metrics.submit
    end
  end

  def self.env
    ENV['SCRUFFY_ENV'] || 'development'
  end

  def self.root
    ENV['SCRUFFY_ROOT'] || File.expand_path('../..', __FILE__)
  end

end
