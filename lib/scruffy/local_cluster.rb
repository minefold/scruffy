class LocalCluster
  FILE = "tmp/local_servers.json"

  def started_at
    @started_at ||= Time.now
  end

  def servers
    if !File.exist?(FILE)
      File.write(FILE, "[]")
    end

    JSON.load(File.read(FILE)).map do |h|
      {
        id: h['id'],
        ip: h['ip'],
        type: h['type'],
        state: h['state'].to_sym,
        started_at: Time.at(h['started_at']),
        tags: h['tags']
      }
    end
  end

  def start_new box_type, tags
    s = servers
    id = "local-#{s.size}"
    LocalCluster.save(s + [{
        id: id,
        ip: '10.10.10.15',
        type: box_type.id,
        state: :starting,
        started_at: Time.now.to_i,
        tags: tags
      }])
    id
  end

  def terminate id
    s = servers
    s.each do |server|
      if server[:id] == id
        server[:state] = :stopping
      end
    end
    LocalCluster.save(s)
  end

  def self.save servers
    json = JSON.pretty_generate(servers.map {|h| {
      id: h[:id],
      ip: h[:ip],
      type: h[:type],
      state: h[:state],
      started_at: h[:started_at].to_i,
      tags: h[:tags]
    }})
    File.write(FILE, json)
  end
end
