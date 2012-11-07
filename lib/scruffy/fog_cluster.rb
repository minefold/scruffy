# uses Fog to talk to EC2
class FogCluster
  def compute_cloud
    @compute_cloud ||= Fog::Compute.new({
      :provider                 => 'AWS',
      :aws_secret_access_key    => ENV['AWS_SECRET_KEY'],
      :aws_access_key_id        => ENV['AWS_ACCESS_KEY'],
      :region                   => ENV['EC2_REGION'] || 'us-east-1'
    })
  end

  def servers
    servers = compute_cloud.servers.select do |s|
      FogCluster.tag_filter.all? {|k,v| s.tags[k.to_s] == v.to_s}
    end

    servers.map do |s|
      p s
      {
        id: s.id,
        ip: s.public_ip_address,
        type: s.flavor_id,
        started_at: s.created_at,
        tags: s.tags
      }
    end
  end

  def self.tag_filter
    {
      "Name" => "worker",
      "environment" => "production"
    }
  end
end
