require 'turn/autorun'
require 'minitest/mock'
require 'scruffy'

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