require 'phraseapp-ruby'

class PhraseAppClient

  def initialize(project_id: nil, token: nil)
    @project_id =
      project_id ||
        if Rails.env.production?
          Settings.phraseapp.project_id
        else
          Settings.phraseapp.test_project_id
        end || ''
    @token = token || Settings.phraseapp.api_token || ''

    credentials = PhraseApp::Auth::Credentials.new(token: @token)
    @client = PhraseApp::Client.new(credentials)
  end

  def logger
    @logger ||=
      if log_file = Settings.phraseapp.log_file
        Logger.new(log_file)
      else
        Rails.logger
      end
  end

  def delete_translation(model)
    deleted = 0
    model.class.translatable_attributes.each do |attribute|
      key = model.build_translation_key(attribute)
      params = PhraseApp::RequestParams::KeysDeleteParams.new(q: key)
      affected = @client.keys_delete(@project_id, params).first.records_affected
      if affected.to_s == '0'
      else
        deleted = deleted + affected
      end
    end
    deleted
  end

  def get_all_translations(locales)
    translations = []

    locales.each do |locale|
      translationsForLocale = download_locale(locale)

      translationsForLocale.each do |type, translationForType|
        translationForType.each do |id, translationValues|
          translationValues.each do |key, value|
            translations.push({
              id: id,
              type: type,
              language: locale,
              key: key,
              content: value
            })
          end
        end
      end
    end

    translations
  end

  def push_locale_file(file, locale, tags: nil)
    begin
      params = PhraseApp::RequestParams::UploadParams.new(
        file: file.path,
        update_translations: true,
        tags: tags || '',
        encoding: 'UTF-8',
        file_format: 'nested_json',
        locale_id: locale
      )

      @client.upload_create(@project_id, params)
    rescue => exception
      message = 'Could not upload file '
      message << "for the following error: #{exception.message}\n"
      message << "#{exception.backtrace[0..14].join("\n")}"
      logger.error message
      raise message if Rails.env.development?
    end
  end

  def delete_all_keys
    begin
      params = PhraseApp::RequestParams::KeysDeleteParams.new(q: '*')
      @client.keys_delete(@project_id, params).first.records_affected
    rescue => exception
      if exception =~ 'unexpected status code (504) received'
        logger.warn 'PhraseAppServer timed out while deleting all keys.'
        -1
      else
        message = 'Could not delete all keys for '
        message << "the following error: #{exception.message}\n"
        message << "#{exception.backtrace[0..14].join("\n")}"
        logger.error message
        raise message if Rails.env.development?
      end
    end
  end

  def add_all_translations(limit: nil)
    [Orga, Event].each do |model_class|
      model_class.limit(limit).each do |model|
        model.force_translatable_attribute_update!
        model.update_or_create_translations
      end
    end
    Rails.logger.info 'finished add_all_translations'
  end

  def delete_unused_keys
    begin
      json = download_locale(Translatable::DEFAULT_LOCALE, true)
      event_ids = json['event'].try(:keys) || []
      orga_ids = json['orga'].try(:keys) || []

      keys_to_destroy =
        get_keys_to_destroy(Orga, orga_ids) +
          get_keys_to_destroy(Event, event_ids)

      deleted = 0
      keys_to_destroy.each do |key|
        params = PhraseApp::RequestParams::KeysDeleteParams.new(q: key)
        affected = @client.keys_delete(@project_id, params).first.records_affected
        deleted = deleted + affected
      end
      Rails.logger.debug "deleted #{deleted} keys."
      return deleted
    rescue => exception
      Rails.logger.error 'error for delete_all_keys_not_used_in_database'
      Rails.logger.error exception.message
      Rails.logger.error exception.backtrace.join("\n")
      raise exception unless Rails.env.production?
    end
  end

  private

  def download_locale(locale, include_empty_translations = false)
    params = PhraseApp::RequestParams::LocaleDownloadParams.new(
      file_format: 'nested_json',
      encoding: 'UTF-8'
    )
    json = @client.locale_download(@project_id, locale, params).force_encoding('UTF-8')
    return JSON.parse json
  end

  def get_keys_to_destroy(model_class, ids)
    list = []
    ids.each do |id|
      if model = model_class.find_by(id: id)
        model_class.translatable_attributes.each do |attribute|
          if model.send(attribute).blank?
            list << model.build_translation_key(attribute)
          end
        end
      else
        list << model_class.build_translation_key(id, '*')
      end
    end
    list
  end

end
