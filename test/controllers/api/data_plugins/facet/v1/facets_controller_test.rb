require 'test_helper'

class Api::DataPlugins::Facet::V1::FacetsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'create facet' do
      assert_difference -> { DataPlugins::Facet::Facet.count } do
        post :create, params: { title: 'new facet' }
        assert_response :created
      end
      json = JSON.parse(response.body)
      facet = DataPlugins::Facet::Facet.last
      assert_equal JSON.parse(facet.to_json), json
    end

    should 'update facet' do
      facet = create(:facet)

      assert_no_difference -> { DataPlugins::Facet::Facet.count } do
        patch :update, params: { id: facet.id, title: 'changed facet' }
        assert_response :ok
      end
      json = JSON.parse(response.body)
      facet.reload
      assert_equal JSON.parse(facet.to_json), json
    end

    should 'remove facet' do
      pp facet = create(:facet)

      assert_difference -> { DataPlugins::Facet::Facet.count }, -1 do
        delete :destroy, params: { id: facet.id }
        assert_response 200
      end
      assert response.body.blank?
    end
  end

end
