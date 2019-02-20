require 'test_helper'

class DataPlugins::Location::V1::LocationsControllerTest < ActionController::TestCase
  test 'get locations' do
    stub_current_user

    orga = create(:orga, state: :active, area: @controller.current_api_v1_user.area)
    DataPlugins::Location::Location.delete_all
    location_to_be_found = create(:afeefa_office, owner: orga)
    location_to_be_found_2 = create(:afeefa_montagscafe, owner: orga)
    location_not_to_be_found = create(:impact_hub, owner: orga)

    get :index
    assert_response :ok
    json = JSON.parse(response.body)
    assert_kind_of Array, json['data']
    assert_equal 3, json['data'].size
  end
end
