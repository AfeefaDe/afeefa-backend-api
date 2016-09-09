require 'test_helper'

class OrgaSerializerTest < ActiveSupport::TestCase

  should 'have correct mapping' do
    orga = create(:orga)
    hash = ActiveModelSerializers::SerializableResource.new(orga, {}).serializable_hash
    assert hash.key?(:data)
    assert_match orga.id.to_s, hash[:data][:links][:self]
    assert hash[:data].key?(:type)
    assert hash[:data].key?(:attributes)
    [
        :title, :description, :created_at, :updated_at
    ].each do |attr|
      assert_equal(
          orga.send(attr.to_s), hash[:data][:attributes][attr.to_s.gsub('_', '-')],
          "mapping failed for attribute #{attr}"
      )
    end
  end

end
