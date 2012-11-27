class Stain
  attr_reader :log
  attr_reader :bus
  attr_reader :boxes_cache, :pinkies_cache, :stains_cache, :boxes, :pinkies

  def initialize bus, boxes_cache, pinkies_cache, stains_cache, boxes, pinkies, servers
    @bus = bus
    @boxes_cache, @pinkies_cache, @stains_cache = boxes_cache, pinkies_cache, stains_cache
    @boxes, @pinkies, @servers = boxes, pinkies, servers

    @log = Mutli::Logger.new
  end
  
  def allocator
    @allocator ||= Allocator.new(@boxes, @pinkies, @servers)
  end
  
  class << self
    attr_reader :all
    
    def inherited(klass)
      (@all ||= []) << klass
    end
  end
end

Dir[File.dirname(__FILE__) + '/stains/*.rb'].each {|file| require file }
