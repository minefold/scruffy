class BoxType
  attr_reader :id,
    :ram_mb,
    :ecus,
    :ami

    AMIS = {
      '64bit' => 'ami-e3b0378a',
        'HVM' => 'ami-a1b037c8'
    }

  def self.definitions
    [
      BoxType.new('m1.small', 1.7 * 1024, 1, AMIS['64bit']),
      BoxType.new('c1.medium', 1.7 * 1024, 5, AMIS['64bit']),
      BoxType.new('c1.xlarge', 7.0 * 1024, 20, AMIS['64bit']),
      BoxType.new('cc2.8xlarge', 60.5 * 1024, 88, AMIS['HVM']),
    ]
  end

  def self.find id
    definitions.find{|box_type| box_type.id == id }
  end

  def initialize id, ram_mb, ecus, ami
    @id, @ram_mb, @ecus, @ami = id, ram_mb, ecus, ami
  end
end