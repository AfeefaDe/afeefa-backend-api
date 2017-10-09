require 'phrase_app_client'

class TranslationSyncJob < ActiveJob::Base
  queue_as :default

  def perform
    Rails.logger.info 'translation sync start'

    @@client.sync_all_translations

    Rails.logger.info 'translation sync finished'
  end
end
