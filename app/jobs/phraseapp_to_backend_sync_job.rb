class PhraseappToBackendSyncJob < ActiveJob::Base
  queue_as :default

  def perform
    @@client ||= ::PhraseAppClient.new
    translations = @@client.get_all_translations(Translatable::TRANSLATABLE_LOCALES)

    if translations.empty?
      Rails.logger.info 'no updates of translation cache necessary'
    else
      num = TranslationCache.rebuild_db_cache!(translations)
      Rails.logger.info "translation cache update succeeded, #{num} translations cached"
    end

    fapi_client = FapiClient.new
    fapi_client.all_updated
  end
end
