require 'turn/autorun'
require 'minitest/mock'
require 'scruffy'

class Pinky
  attr_reader :id, :state, :free_disk_mb, :free_ram_mb, :idle_cpu
  attr_reader :servers

  def initialize id, state, free_disk_mb, free_ram_mb, idle_cpu, servers
    @id = id
    @state = state
    @free_disk_mb = free_disk_mb
    @free_ram_mb = free_ram_mb
    @idle_cpu = idle_cpu
    @servers = servers
  end
end

class Server
  attr_reader :id, :state, :port
  
  def initialize id, state, port
    @id = id
    @state = state
    @port = port
  end
end

class Scruffy
  def sweep

  end
end

class Pinkies < Array
  def initialize bus
    @bus = bus
  end

  def update!
    self.clear
    pinky_states = @bus.pinky_states
    pinky_servers = @bus.pinky_servers
    server_states = @bus.server_states

    @bus.heartbeats.each do |hb|
      state = pinky_states.find{|ps| ps[:id] == hb[:id]}[:state]

      servers = pinky_servers.select{|ps| ps[:pinky_id] == hb[:id] }.map do |ps|
        Server.new(
          ps[:id], 
          server_states.find{|ss| ss[:id] == ps[:id]}[:state],
          ps[:port]
        )
      end

      self << Pinky.new(
        hb[:id],
        state,
        hb[:free_disk_mb],
        hb[:free_ram_mb],
        hb[:idle_cpu],
        servers
      )
    end

  end
end

describe Pinkies do
  let(:bus) do
    bus = MiniTest::Mock.new
    bus.expect(:heartbeats, [
      id: "i-12345",
      free_disk_mb: 73132,
      free_ram_mb: 632,
      idle_cpu: 88,
    ])
    bus.expect(:pinky_states, [
      id: "i-12345",
      state: "up",
    ])
    bus.expect(:pinky_servers, [{
      id: "6789",
      pinky_id: "i-12345",
      port: 10000,
    },  {
      id: "7201",
      pinky_id: "i-12345",
      port: 10100,
    }])
    bus.expect(:server_states, [{
      id: "6789",
      state: "up",
    },  {
      id: "7201",
      state: "up",
    }])
    bus
  end

  let(:pinkies) { Pinkies.new(bus) }

  it "updates from pinky bus" do
    pinkies.count.must_equal 0
    pinkies.update!
    pinkies.count.must_equal 1
  end

  it "has pinkies" do
    pinkies.update!
    pinky = pinkies.first
    pinky.id.must_equal "i-12345"
    pinky.state.must_equal "up"
    pinky.free_disk_mb.must_equal 73132
    pinky.free_ram_mb.must_equal 632
    pinky.idle_cpu.must_equal 88
  end

  it "has servers" do
    pinkies.update!
    pinky = pinkies.first
    pinky.servers.size.must_equal 2

    server = pinky.servers.first
    server.id.must_equal "6789"
    server.port.must_equal 10000
  end
end