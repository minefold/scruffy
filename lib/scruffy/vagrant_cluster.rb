# uses vagrant for pinkies (sort of)
class VagrantCluster
  def started_at
    @started_at ||= Time.now
  end
  
  def servers
    [{
      id: 'precise64',
      ip: '10.10.10.15',
      type: 'c1.xlarge',
      state: 'up',
      started_at: started_at,
      tags: { "Name" => "pinky" }
    }]
  end
end
