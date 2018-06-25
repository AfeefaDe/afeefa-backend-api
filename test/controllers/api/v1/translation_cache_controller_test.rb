require 'test_helper'

include ActiveJob::TestHelper
Rails.application.config.active_job.queue_adapter = :test

class Api::V1::TranslationCacheControllerTest < ActionController::TestCase

  setup do
    WebMock.allow_net_connect!(allow_localhost: false)
  end

  teardown do
    WebMock.disable_net_connect!(allow_localhost: false)
  end

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get status 401 for missing phraseapp webhook token' do
      post :phraseapp_webhook
      assert_response :unauthorized
    end

    should 'get status 401 for wrong phraseapp webhook token' do
      post :phraseapp_webhook, params: { token: '123' }
      assert_response :unauthorized
    end

    should 'get status 200 for valid phraseapp webhook token' do
      @controller.expects(:phraseapp_webhook)
      post :phraseapp_webhook, params: { token: Settings.phraseapp.webhook_api_token }
      assert_response :no_content
    end

    should 'start cache job upon created translation' do
      orga = create(:orga)

      json = parse_json_file file: 'translation_webhook.json' do |payload|
        payload.gsub!('<translation_operation>', 'create')
        payload.gsub!('<translation_content>', 'i am a magician')
        payload.gsub!('<translation_key>', "orga.#{orga.id}.title")
        payload.gsub!('<translation_locale>', 'en')
      end

      request.query_string = "token=#{Settings.phraseapp.webhook_api_token}"
      request.env['RAW_POST_DATA'] = json.to_json

      FapiClient.any_instance.expects(:request).with(has_entries(type: 'orga', id: orga.id, locale: 'en'))

      post :phraseapp_webhook

      assert_response :created, response.body

      cache = TranslationCache.where(cacheable_type: 'orga', cacheable_id: orga.id, language: 'en').first

      assert_equal 'i am a magician', cache.title
    end

    should 'start cache job upon updated translation' do
      orga = create(:orga)

      TranslationCache.create!(
        cacheable_type: 'orga',
        cacheable_id: orga.id,
        title: orga.title,
        short_description: orga.short_description,
        language: 'ar'
      )

      json = parse_json_file file: 'translation_webhook.json' do |payload|
        payload.gsub!('<translation_operation>', 'update')
        payload.gsub!('<translation_content>', 'رفضت هيئة الإشراف على البث التلفزيوني')
        payload.gsub!('<translation_key>', "orga.#{orga.id}.title")
        payload.gsub!('<translation_locale>', 'ar')
      end

      request.query_string = "token=#{Settings.phraseapp.webhook_api_token}"
      request.env['RAW_POST_DATA'] = json.to_json

      FapiClient.any_instance.expects(:request).with(has_entries(type: 'orga', id: orga.id, locale: 'ar'))

      post :phraseapp_webhook

      assert_response :ok, response.body

      cache = TranslationCache.where(cacheable_type: 'orga', cacheable_id: orga.id, language: 'ar').first

      assert_equal 'رفضت هيئة الإشراف على البث التلفزيوني', cache.title
    end

    should 'start cache job upon updated translation with event' do
      event = create(:event)

      TranslationCache.create!(
        cacheable_type: 'event',
        cacheable_id: event.id,
        title: event.title,
        short_description: event.short_description,
        language: 'ar'
      )

      json = parse_json_file file: 'translation_webhook.json' do |payload|
        payload.gsub!('<translation_operation>', 'update')
        payload.gsub!('<translation_content>', 'رفضت هيئة الإشراف على البث التلفزيوني')
        payload.gsub!('<translation_key>', "event.#{event.id}.title")
        payload.gsub!('<translation_locale>', 'ar')
      end

      request.query_string = "token=#{Settings.phraseapp.webhook_api_token}"
      request.env['RAW_POST_DATA'] = json.to_json

      FapiClient.any_instance.expects(:request).with(has_entries(type: 'event', id: event.id, locale: 'ar'))

      post :phraseapp_webhook

      assert_response :ok, response.body

      cache = TranslationCache.where(cacheable_type: 'event', cacheable_id: event.id, language: 'ar').first

      assert_equal 'رفضت هيئة الإشراف على البث التلفزيوني', cache.title
    end

    should 'start cache job upon updated translation with facet_item' do
      facet_item = create(:facet_item)

      TranslationCache.create!(
        cacheable_type: 'facet_item',
        cacheable_id: facet_item.id,
        title: facet_item.title,
        language: 'ar'
      )

      json = parse_json_file file: 'translation_webhook.json' do |payload|
        payload.gsub!('<translation_operation>', 'update')
        payload.gsub!('<translation_content>', 'رفضت هيئة الإشراف على البث التلفزيوني')
        payload.gsub!('<translation_key>', "facet_item.#{facet_item.id}.title")
        payload.gsub!('<translation_locale>', 'ar')
      end

      request.query_string = "token=#{Settings.phraseapp.webhook_api_token}"
      request.env['RAW_POST_DATA'] = json.to_json

      FapiClient.any_instance.expects(:request).with(has_entries(type: 'facet_item', id: facet_item.id, locale: 'ar'))

      post :phraseapp_webhook

      assert_response :ok, response.body

      cache = TranslationCache.where(cacheable_type: 'facet_item', cacheable_id: facet_item.id, language: 'ar').first

      assert_equal 'رفضت هيئة الإشراف على البث التلفزيوني', cache.title
    end

    should 'remove cache record if all values are empty' do
      event = create(:event)

      TranslationCache.create!(
        cacheable_type: 'event',
        cacheable_id: event.id,
        title: event.title,
        language: 'en'
      )

      json = parse_json_file file: 'translation_webhook.json' do |payload|
        payload.gsub!('<translation_operation>', 'update')
        payload.gsub!('<translation_content>', '')
        payload.gsub!('<translation_key>', "event.#{event.id}.title")
        payload.gsub!('<translation_locale>', 'en')
      end

      request.query_string = "token=#{Settings.phraseapp.webhook_api_token}"
      request.env['RAW_POST_DATA'] = json.to_json

      FapiClient.any_instance.expects(:request).with(has_entries(type: 'event', id: event.id, locale: 'en'))

      assert_difference -> { TranslationCache.count }, -1 do
        post :phraseapp_webhook
      end

      assert_response :ok, response.body
      assert_nil TranslationCache.find_by(cacheable_type: 'event', cacheable_id: event.id, language: 'en')
    end


    should 'start cache job upon updated translation with navigation_item' do
      navigation_item = create(:fe_navigation_item)

      TranslationCache.create!(
        cacheable_type: 'navigation_item',
        cacheable_id: navigation_item.id,
        title: navigation_item.title,
        language: 'ar'
      )

      json = parse_json_file file: 'translation_webhook.json' do |payload|
        payload.gsub!('<translation_operation>', 'update')
        payload.gsub!('<translation_content>', 'رفضت هيئة الإشراف على البث التلفزيوني')
        payload.gsub!('<translation_key>', "navigation_item.#{navigation_item.id}.title")
        payload.gsub!('<translation_locale>', 'ar')
      end

      request.query_string = "token=#{Settings.phraseapp.webhook_api_token}"
      request.env['RAW_POST_DATA'] = json.to_json

      FapiClient.any_instance.expects(:request).with(has_entries(type: 'navigation_item', id: navigation_item.id, locale: 'ar'))

      post :phraseapp_webhook

      assert_response :ok, response.body

      cache = TranslationCache.where(cacheable_type: 'navigation_item', cacheable_id: navigation_item.id, language: 'ar').first

      assert_equal 'رفضت هيئة الإشراف على البث التلفزيوني', cache.title
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

        FapiClient.any_instance.expects(:all_updated).with()

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
