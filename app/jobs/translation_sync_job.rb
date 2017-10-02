require 'phrase_app_client'

class TranslationSyncJob < ActiveJob::Base
  queue_as :default

  def perform
    Rails.logger.info 'translation sync start'
    @@client ||= ::PhraseAppClient.new
    Rails.logger.info '- add translations start'
    @@client.add_all_translations
    Rails.logger.info '- delete unused keys start'
    @@client.delete_unused_keys(dry_run: false)
    Rails.logger.info 'translation sync finished'
  end
end
