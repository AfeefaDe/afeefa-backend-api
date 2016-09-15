require 'test_helper'

class EventSerializerTest < ActiveSupport::TestCase

  should 'have correct mapping' do
    e = event
    hash = ActiveModelSerializers::SerializableResource.new(e, {}).serializable_hash
    assert hash.key?(:data)
    assert_match e.id.to_s, hash[:data][:links][:self]
    assert hash[:data].key?(:type)
    assert hash[:data].key?(:attributes)
    [
        :title, :description, :created_at, :updated_at
    ].each do |attr|
      assert_equal(
          e.send(attr.to_s), hash[:data][:attributes][attr.to_s.gsub('_', '-')],
          "mapping failed for attribute #{attr}"
      )
    end
  end

end