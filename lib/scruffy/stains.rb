class Stain
  attr_reader :log
  attr_reader :boxes_cache, :pinkies_cache, :boxes, :pinkies

  def initialize boxes_cache, pinkies_cache, boxes, pinkies
    @boxes_cache, @pinkies_cache = boxes_cache, pinkies_cache
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