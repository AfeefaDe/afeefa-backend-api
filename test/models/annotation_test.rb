require 'test_helper'

class AnnotationTest < ActiveSupport::TestCase

  should 'render json' do
    annotation = Annotation.last
    assert_jsonable_hash(annotation)
    assert_jsonable_hash(annotation, attributes: annotation.class.attribute_whitelist_for_json)
    assert_jsonable_hash(annotation,
      attributes: annotation.class.attribute_whitelist_for_json,
      relationships: annotation.class.relation_whitelist_for_json)
    assert_jsonable_hash(annotation, relationships: annotation.class.relation_whitelist_for_json)
  end

end
