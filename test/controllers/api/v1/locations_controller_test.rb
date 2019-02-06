require 'test_helper'

class DataPlugins::Location::V1::LocationsControllerTest < ActionController::TestCase
  test 'search for locations' do
    stub_current_user

    DataPlugins::Location::Location.delete_all
    location_to_be_found = create(:afeefa_office)
    location_to_be_found_2 = create(:afeefa_montagscafe)
    location_not_to_be_found = create(:impact_hub)

    get :index, params: { search_term: 'afee' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_kind_of Array, json['data']
    skip 'search filter needs to be implemented'
    assert_equal 2, json['data'].size
    expected_titles = [location_to_be_found.title, location_to_be_found_2.title].sort
    assert_equal expected_titles, json['data'].map { |x| x['attributes']['title'] }.sort
  end
end
