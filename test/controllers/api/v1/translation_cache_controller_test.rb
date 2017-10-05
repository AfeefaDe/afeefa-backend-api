require 'test_helper'

include ActiveJob::TestHelper
Rails.application.config.active_job.queue_adapter = :test

class Api::V1::TranslationCacheControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get status 401 for unauthenticated phraseapp webhook' do
      get :phraseapp_webhook
      assert_response :unauthorized
    end

    should 'get status 200 for token authenticated phraseapp webhook' do
      get :phraseapp_webhook, params: { token: Settings.phraseapp.webhook_api_token }

      assert_response :ok

      json = JSON.parse(response.body)
      assert_equal 'ok', json['status']
    end

    should 'get last updated timestamp' do
      get :index

      json = JSON.parse(response.body)
      assert_equal TranslationCache.minimum(:updated_at) || Time.at(0), json['updated_at']
    end

    should 'trigger cache rebuild' do
      # TODO: Check cassette and write tests for other responses
      VCR.use_cassette('translation_cache_controller_test_trigger_cache_rebuild') do
        get :index
        assert_response :ok
        time_before = JSON.parse(response.body)['updated_at']

        perform_enqueued_jobs do
          post :update
        end

        assert_enqueued_jobs 0

        post_response = response.status

        get :index

        case post_response
          when 200 # caching table got updated –> timestamp changed
            assert_operator time_before, :<, JSON.parse(response.body)['updated_at']
          when 204 # no updated was necessary -> nothing changed
            assert_equal time_before, JSON.parse(response.body)['updated_at']
          else
            fail 'unexpacted behavior on translation cache update'
        end

        # caching table contains no 'de' entries
        assert_nil TranslationCache.find_by(language: Translatable::DEFAULT_LOCALE)
      end
    end
  end

end
