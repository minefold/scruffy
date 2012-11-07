require 'turn/autorun'
require 'minitest/mock'
require 'scruffy'

class Pinky
  attr_reader :id, :state
end

class Server
  attr_reader :id, :state
end

class Scruffy
  def sweep

  end
end

describe BoxType do
  let(:box_type) { BoxType.find('c1.xlarge') }
  it "has attributes" do
    box_type.id.must_equal 'c1.xlarge'
    box_type.ram.must_equal 7.0 * 1024
    box_type.ecus.must_equal 20
    box_type.ami.must_equal BoxType::AMIS['64bit']
  end
end

describe Boxes do
  let(:started_at) { Time.now }
  let(:cluster) do
    cluster = MiniTest::Mock.new
    cluster.expect(:servers, [
      id: "i-12345",
      ip: "1.2.3.4",
      type: 'c1.xlarge',
      started_at: started_at,
      tags: {'name' => 'pinky'}
    ])
    cluster
  end

  let(:boxes) { Boxes.new(cluster) }

  it "updates from cluster" do
    boxes.count.must_equal 0
    boxes.update!
    boxes.count.must_equal 1
  end

  it "has boxes" do
    boxes.update!
    box = boxes.first
    box.id.must_equal "i-12345"
    box.ip.must_equal "1.2.3.4"
    box.type.id.must_equal "c1.xlarge"
    box.started_at.must_equal started_at
    box.tags.must_equal({'name' => 'pinky'})
  end
end

describe Box do
  let(:started_at) { Time.now }
  let(:box_type) { BoxType.find('c1.xlarge') }
  let(:box) { Box.new('i-12345', '1.2.3.4', box_type, :starting, started_at) }

  it "has attributes" do
    box.id.must_equal 'i-12345'
    box.type.must_equal box_type
    box.state.must_equal :starting
    box.started_at.must_equal started_at
  end
end