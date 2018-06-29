require 'test_helper'

class TranslationCacheTest < ActiveSupport::TestCase

  setup do
    WebMock.allow_net_connect!(allow_localhost: false)
  end

  teardown do
    WebMock.disable_net_connect!(allow_localhost: false)
  end

  should 'rebuild cache' do
    Settings.phraseapp.stubs(:active).returns(true)

    # create couple of entries that will be translated in order to get the correct timestamp updated_at below
    create(:orga_with_random_title, id: 1532) # @see vcr cassette ids
    create(:orga_with_random_title, id: 1690) # @see vcr cassette ids
    create(:event, id: 1136) # @see vcr cassette ids
    create(:event, id: 1271) # @see vcr cassette ids, only 1 field translated

      translations = nil

    VCR.use_cassette('get_all_translations') do
      translations = client.get_all_translations(Translatable::TRANSLATABLE_LOCALES)
    end

    assert translations.any?
    changes = TranslationCache.rebuild_db_cache!(translations)

    assert_equal 7, changes

    countTranslatedDbFields = TranslationCache.where.not(title: nil).count + TranslationCache.where.not(short_description: nil).count
    assert_equal 7, countTranslatedDbFields

    assert_equal 0, TranslationCache.where(language: Translatable::DEFAULT_LOCALE).count
  end

  private

  def client
    @@client ||= PhraseAppClient.new
  end

end
