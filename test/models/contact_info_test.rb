require "test_helper"

class ContactInfoTest < ActiveSupport::TestCase
  def contact_info
    @contact_info ||= ContactInfo.new
  end

  def test_valid
    assert contact_info.valid?
  end
end
