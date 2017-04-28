require 'test_helper'

class AnnotationTest < ActiveSupport::TestCase

  should 'render json' do
    object_keys = [:id, :type, :attributes, :relationships]
    attribute_keys = [:detail]
    relationships = [:annotation_category, :entry]
    todo = Annotation.new(entry: create(:orga), annotation_category: AnnotationCategory.first, detail: 'FooBar')
    assert todo.save, todo.errors.messages
    json = JSON.parse(todo.to_json).deep_symbolize_keys
    assert_equal(object_keys.sort, json.keys.sort)
    assert_equal(attribute_keys.sort, json[:attributes].keys.sort)
    assert_equal(relationships.sort, json[:relationships].keys.sort)
    relationships.each do |relation|
      assert_equal [:data], json[:relationships][relation].keys
      if (data = json[:relationships][relation][:data]).is_a?(Array)
        json[:relationships][relation][:data].each_with_index do |element, index|
          assert_equal todo.send(relation)[index].to_hash, element
        end
      else
        assert_equal todo.send(relation).to_hash(attributes: nil, relationships: nil), data
      end
    end
  end

end
