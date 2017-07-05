require 'test_helper'

class AnnotationTest < ActiveSupport::TestCase

  should 'render json' do
    object_keys = [:id, :type, :attributes]
    attribute_keys = [:annotation_category_id, :detail]
    annotation = Annotation.new(entry: create(:orga), annotation_category: AnnotationCategory.first, detail: 'FooBar')
    assert annotation.save, annotation.errors.messages
    json = JSON.parse(annotation.to_json).deep_symbolize_keys
    assert_equal(object_keys.sort, json.keys.sort)
    assert_equal(attribute_keys.sort, json[:attributes].keys.sort)
    assert_not json.key?(:relationships)
  end

  should 'render todos json' do
    object_keys = [:id, :type, :relationships]
    relationships = [:annotation, :annotation_category, :entry]
    todo = Annotation.new(entry: create(:orga), annotation_category: AnnotationCategory.first, detail: 'FooBar')
    assert todo.save, todo.errors.messages
    json = JSON.parse(todo.to_todos_hash.to_json).deep_symbolize_keys
    assert_equal(object_keys.sort, json.keys.sort)
    assert_not json.key?(:attributes)
    assert_equal(relationships.sort, json[:relationships].keys.sort)
    relationships.each do |relation|
      assert_equal [:data], json[:relationships][relation].keys
      if (data = json[:relationships][relation][:data]).is_a?(Array)
        json[:relationships][relation][:data].each_with_index do |element, index|
          assert_equal todo.send(relation)[index].to_hash, element
        end
      else
        expected =
          if todo.respond_to?("#{relation}_to_hash")
            todo.send("#{relation}_to_hash")
          else
            todo.send(relation).to_hash(attributes: nil, relationships: nil)
          end
        # only care for type and id
        assert_equal expected.slice(:type, :id), data.slice(:type, :id)
      end
    end
  end

end
