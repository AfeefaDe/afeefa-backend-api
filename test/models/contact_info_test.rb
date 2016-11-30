require 'test_helper'

class ContactInfoTest < ActiveSupport::TestCase

  should 'validate attributes' do
    contact_info = ContactInfo.new
    assert_not contact_info.valid?
    assert_match 'muss ausgefüllt werden', contact_info.errors[:contactable].first
    assert_match 'muss ausgefüllt werden', contact_info.errors[:contact_person].first
    assert_match 'Mail-Adresse oder Telefonnummer muss angegeben werden.', contact_info.errors[:mail].first
    assert_match 'Mail-Adresse oder Telefonnummer muss angegeben werden.', contact_info.errors[:phone].first
  end

end
