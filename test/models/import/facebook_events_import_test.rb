require 'test_helper'

module Import
  class FacebookEventsImportTest < ActiveSupport::TestCase

    should 'check element for coordinates in area coordinates' do
      element = { place: { location: { latitude: '0', longitude: '0' } } }.deep_stringify_keys
      Translatable::AREAS.each do |area|
        assert_equal false, FacebookEventsImport.element_in_area?(element: element, area: area)
      end
    end

    should 'import complete list' do
      config = {
        dresden: {
          orga0815: 'fb_id_0815'
        }
      }.deep_stringify_keys
      Settings.facebook.stubs(:pages_for_events).returns(config)

      # TODO: add a real response here:
      response = [
        {
          place: {
            location: {
              latitude: '0',
              longitude: '0'
            }
          }
        }
      ]
      FacebookClient.expects(:new).returns(@client = mock())
      @client.expects(:raw_get_upcoming_events).with do |options|
        assert_equal config['dresden'].keys.first, options[:page]
        assert_equal config['dresden'].values.first, options[:page_id]
        true
      end.returns(response)

      assert_difference -> { Event.by_area('dresden').count } do
        assert_equal 1, FacebookEventsImport.import
      end
    end

  end
end
