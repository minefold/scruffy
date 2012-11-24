describe Pinkies do
  let(:bus) do
    bus = MiniTest::Mock.new
    bus.expect(:pinky_heartbeats, [
      id: "i-12345",
      freeDiskMb: 73132,
      freeRamMb: 632,
      idleCpu: 88,
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