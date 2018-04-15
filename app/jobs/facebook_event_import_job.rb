class FacebookEventImportJob < ActiveJob::Base
  queue_as :default

  def perform(limit: nil)
    Rails.logger.info 'facebook event import start'

    Import::FacebookEventsImport.import(limit: limit)

    Rails.logger.info 'facebook event import finished'
  end
end
