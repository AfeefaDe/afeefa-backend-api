require 'phrase_app_client'

class TranslationCacheJob < ActiveJob::Base
  queue_as :default

  def perform
    @@client ||= ::PhraseAppClient.new
    translations = @@client.get_all_translations

    if translations.empty?
      Rails.logger.info 'no updates of translation cache necessary'
    else
      num = TranslationCache.rebuild_db_cache!(translations)
      Rails.logger.info "translation cache update succeeded, #{num} translations cached"
    end
  end
end
