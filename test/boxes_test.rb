require 'turn/autorun'
require 'minitest/mock'
require 'scruffy'

describe Boxes do
  let(:started_at) { Time.now }
  let(:cluster) do
    cluster = MiniTest::Mock.new
    cluster.expect(:servers, [
      id: "i-12345",
      ip: "1.2.3.4",
      type: 'c1.xlarge',
      state: 'starting',
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
    box.state.must_equal :starting
    box.started_at.must_equal started_at
    box.tags.must_equal({'name' => 'pinky'})
  end
end