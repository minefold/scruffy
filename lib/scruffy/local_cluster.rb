class LocalCluster
  def started_at
    @started_at ||= Time.now
  end
  
  def file
    "tmp/local_servers.json"
  end

  def servers
    if !File.exist?(file)
      File.write(file, "[]")
    end

    JSON.load(File.read(file)).symbolize_keys
  end
  
  def start_new box_type, tags
    File.write(file, JSON.dump(servers + [{
        id: 'precise64',
        ip: '10.10.10.15',
        type: box_type.id,
        state: :starting,
        started_at: Time.now,
        tags: tags
      }]
    ))
  end
end

# example json:
# [{
#   "id": "precise64",
#   "ip": "10.10.10.15",
#   "type": "c1.xlarge",
#   "state": "up",
#   "started_at": 1352409074,
#   "tags": { "Name": "pinky" }
# }]
