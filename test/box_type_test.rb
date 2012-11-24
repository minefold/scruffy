require 'turn/autorun'
require 'minitest/mock'
require 'scruffy'

describe BoxType do
  let(:box_type) { BoxType.find('c1.xlarge') }
  it "has attributes" do
    box_type.id.must_equal 'c1.xlarge'
    box_type.ram_mb.must_equal 7.0 * 1024
    box_type.ecus.must_equal 20
    box_type.ami.must_equal BoxType::AMIS['64bit']
  end
end
