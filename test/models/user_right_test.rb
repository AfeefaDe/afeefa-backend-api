require "test_helper"

describe UserRight do
  let(:user_right) { UserRight.new }

  it "must be valid" do
    value(user_right).must_be :valid?
  end
end
