# interacts with EC2/Other Cloud
class Boxes < Array
  def initialize cluster
    @cluster = cluster
  end

  def update!
    self.clear
    @cluster.servers.each do |s|
      self << Box.new(
        s[:id],
        s[:ip],
        BoxType.find(s[:type]),
        s[:state].to_sym,
        s[:started_at],
        s[:tags]
      )
    end
  end
  
  def find_id(id)
    self.find {|b| b.id == id }
  end

  def start_new box_type
    @cluster.start_new box_type.id, 
      box_type.ami, 
      "Name" => "pinky", 
      "environment" => Scruffy.env
  end

  def terminate id
    @cluster.terminate id
  end
end
