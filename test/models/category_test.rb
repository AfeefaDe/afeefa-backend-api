require 'test_helper'

class CategoryTest < ActiveSupport::TestCase

  test 'render json' do
    category = create(:category)
    assert_jsonable_hash(category)
    assert_jsonable_hash(category, attributes: category.class.attribute_whitelist_for_json)
    assert_jsonable_hash(category,
      attributes: category.class.attribute_whitelist_for_json,
      relationships: category.class.relation_whitelist_for_json)
    assert_jsonable_hash(category, relationships: category.class.relation_whitelist_for_json)
  end

end
