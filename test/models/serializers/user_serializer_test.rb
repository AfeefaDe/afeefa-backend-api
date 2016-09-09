require 'test_helper'

class UserSerializerTest < ActiveSupport::TestCase

  should 'have correct mapping' do
    user = user
    hash = ActiveModelSerializers::SerializableResource.new(user, {}).serializable_hash
    assert hash.key?(:data)
    assert_match user.id.to_s, hash[:data][:links][:self]
    assert hash[:data].key?(:type)
    assert hash[:data].key?(:attributes)
    [
        :email, :forename, :surname
    ].each do |attr|
      assert_equal(
          user.send(attr.to_s), hash[:data][:attributes][attr.to_s.gsub('_', '-')],
          "mapping failed for attribute #{attr}"
      )
    end
  end

end
