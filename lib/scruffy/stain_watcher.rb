module StainWatcher
  # hooks
  def stain_gone(stain_id); end
  def stain_noticed(stain); end

  module ClassMethods
    attr_reader :stain_type

    def stain(type)
      @type = type
    end
  end

  def stain_type
    self.class.stain_type
  end

  def current_stains
    @stains_cache.in_state(stain_type)
  end

  def new_stain_ids
    affected_ids - current_stains.ids
  end

  def no_longer_stains
    current_stains.ids - affected_ids
  end

  def clean
    new_stain_ids.each do |stain_id|
      notice stain_id
      stain_noticed stain_id
    end

    no_longer_stains.each do |stain_id|
      forget stain_id
      stain_gone stain_id
    end

    current_stains.each do |stain|
      check_stain stain
    end
  end

  def notice(id)
    stain = EntityStateChange.new(
      id,
      :missing_server_state,
      Time.now
    )
    @stains_cache << stain
    stain
  end

  def forget id
    @stains_cache.delete(id)
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end