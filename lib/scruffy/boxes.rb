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
        s[:state],
        s[:started_at],
        s[:tags]
      )
    end
  end
end
