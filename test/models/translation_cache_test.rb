require 'test_helper'

class TranslationCacheTest < ActiveSupport::TestCase

  should 'rebuild cache' do
    Settings.phraseapp.stubs(:active).returns(true)

    translations = nil

    VCR.use_cassette('get_all_translations') do
      translations = client.get_all_translations
    end

    VCR.use_cassette('rebuild_translation_cache') do
      assert translations.any?
      changes = TranslationCache.rebuild_db_cache!(translations)

      assert_equal translations.count, changes

      countTranslatedDbFields = TranslationCache.where.not(title: nil).count + TranslationCache.where.not(short_description: nil).count
      assert_equal translations.count, countTranslatedDbFields

      # initial there was only english and german,
      # german should not be in caching table
      assert_equal 0, TranslationCache.where(language: 'de').count
    end
  end

  private

  def client
    skip 'phraseapp deactivated' unless phraseapp_active?
    @@client ||= PhraseAppClient.new
  end

end
