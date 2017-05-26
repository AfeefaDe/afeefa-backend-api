require 'test_helper'

class Api::V1::TranslationCacheControllerTest < ActionController::TestCase

  should 'get last updated timestamp unauthorized' do
    skip
    get :index
    assert_response :unauthorized

    get :index, params: { foo: 'bar' }
    assert_response :unauthorized

    get :index, params: { token: 'abc' }
    assert_response :unauthorized

    get :index, params: { token: Settings.translations.api_token }
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal TranslationCache.minimum(:updated_at) || Time.at(0), json['updated_at']
  end

  should 'trigger cache update on post' do
    get :index, params: { token: Settings.translations.api_token }
    assert_response :ok
    time_before = JSON.parse(response.body)['updated_at']

    post :update
    assert_response :ok

    get :index, params: { token: Settings.translations.api_token }
    assert_operator time_before, :<, JSON.parse(response.body)['updated_at']

  end
end