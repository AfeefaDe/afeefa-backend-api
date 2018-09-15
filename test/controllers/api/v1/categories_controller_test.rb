require 'test_helper'

class Api::V1::CategoriesControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'I want to get all categories' do
      create(:category)

      area = @controller.current_api_v1_user.area

      other_category = Category.last
      other_category.area = area + '_other'
      assert other_category.save

      categories = Category.by_area(area)
      assert categories.count < Category.count
      assert_not_includes categories, other_category

      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal categories.count, json['data'].size
      json['data'].each do |category_json|
        assert id = category_json['id']
        assert category = Category.find(id)
        if (parent_id = category.parent_id).blank?
          assert category_json['relationships']['parent_category']['data'].blank?
        else
          assert_equal parent_id.to_s, category_json['relationships']['parent_category']['data']['id']
        end
      end
    end
  end

end
