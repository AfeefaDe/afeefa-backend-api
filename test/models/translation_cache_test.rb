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
      # initial there was only english and german,
      # german should not be in caching table
      assert_equal translations.count / 2, changes
    end
  end

  private

  def client
    skip 'phraseapp deactivated' unless phraseapp_active?
    @@client ||= PhraseAppClient.new
  end

end
