class BoxType
  attr_reader :id,
    :ram,
    :ecus,
    :ami,
    :player_cap,
    :ram_slot,
    :players_per_slot

    ECUS_PER_SERVER = 1.25
    RAM_PER_PLAYER = 128
    OS_RAM_BUFFER = 0.1 # let the OS have this much ram

    INSTANCE_PLAYER_BUFFER = 5 # needs to be space for 5 players to start a world on a box

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

  def initialize id, ram, ecus, ami
    @id, @ram, @ecus, @ami = id, ram, ecus, ami
  end
  
  def server_slots
    (ecus / ECUS_PER_SERVER).round
  end
end