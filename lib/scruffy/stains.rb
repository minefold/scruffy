class Stain
  attr_reader :log
  attr_reader :bus
  attr_reader :boxes_cache, :pinkies_cache, :stains_cache, :boxes, :pinkies

  def initialize bus, boxes_cache, pinkies_cache, stains_cache, boxes, pinkies
    @bus = bus
    @boxes_cache, @pinkies_cache, @stains_cache = boxes_cache, pinkies_cache, stains_cache
    @boxes, @pinkies = boxes, pinkies

    @log = Logger.new
  end
  
  class << self
    attr_reader :all
    
    def inherited(klass)
      (@all ||= []) << klass
    end
  end
end

Dir[File.dirname(__FILE__) + '/stains/*.rb'].each {|file| require file }
