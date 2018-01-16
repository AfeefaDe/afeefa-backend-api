require "test_helper"

describe OrgaType do
  let(:orga_type) { OrgaType.new }

  it "must be valid" do
    value(orga_type).must_be :valid?
  end
end
