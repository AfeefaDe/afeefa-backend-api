require 'phrase_app_client'

class TranslationSyncJob < ActiveJob::Base
  queue_as :default

  # 1. remove all unused keys
  # 2. add missing or update invalid keys
  # foreach download_locale de keys
  # - remove if not existing any longer
  # - get entry
  #   - if !entry.attribute in json - add key
  #   - if entry.attribute changed - update key
  def perform
    Rails.logger.info 'translation sync start'

    @@client.sync_all_translations

    Rails.logger.info 'translation sync finished'
  end
end
