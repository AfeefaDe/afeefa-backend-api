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
    @fallback_list = Settings.phraseapp.fallback_list || []

    credentials = PhraseApp::Auth::Credentials.new(token: @token)
    @client = PhraseApp::Client.new(credentials)
    initialize_locales_for_project
  end

  def locales
    @locales.try(:keys)
  end

  def logger
    @logger ||=
      if log_file = Settings.phraseapp.log_file
        Logger.new(log_file)
      else
        Rails.logger
      end
  end

  def create_or_update_translation(model, locale)
    responses = []
    model.class.translatable_attributes.each do |attribute|
      begin
        content = model.send(attribute)
        key = model.build_translation_key(attribute)
        key_id =
          find_key_id_by_key_name(key) ||
            create_key(key)
        next if content.blank?

        if translation_id = find_translation_id_by_key_id_and_locale(key_id, locale)
          responses << update_translation_for_translation_id(translation_id, content)
        else
          responses << create_translation_for_key(key_id, locale, content)
        end
      rescue => exception
        message = "Could not create or update translation for \n"
        message << "model #{model.id}, '#{model.title}' and \n"
        message << "locale '#{locale}' and key '#{key}' with \n"
        message << "content '#{content}' for "
        message << "the following error: #{exception.message}\n"
        message << "#{exception.backtrace[0..14].join("\n")}"
        logger.error message
        raise message if Rails.env.development?
      end
    end
    responses
  end

  def delete_translation(model, dry_run: true, only_blank: false)
    deleted = 0
    model.class.translatable_attributes.each do |attribute|
      key = model.build_translation_key(attribute)

      if only_blank
        next unless model.send(attribute).blank?
      end

      if dry_run
        Rails.logger.info "delete key #{key}"
      else
        params = PhraseApp::RequestParams::KeysDeleteParams.new(q: key)
        affected = @client.keys_delete(@project_id, params).first.records_affected
        if affected.to_s == '0'
        else
          deleted = deleted + affected
        end
      end
    end
    deleted
  end

  def get_translation(model, locale, fallback: true)
    {}.tap do |translation_hash|
      model.class.translatable_attributes.each do |attribute|
        key =
          if model.class.to_s.start_with?('Neos::')
            "entry.#{model.entry_id}.#{attribute}"
          else
            model.build_translation_key(attribute)
          end
        key_id = find_key_id_by_key_name(key)
        next unless key_id

        params = PhraseApp::RequestParams::TranslationsByKeyParams.new()
        available_translations = @client.translations_by_key(@project_id, key_id, 1, 100000, params)[0]

        unless @fallback_list.include?(locale)
          @fallback_list.unshift(locale)
        end
        (available_translations || []).each do |translation|
          local_codes_to_use = [locale]
          local_codes_to_use += @fallback_list if fallback

          for locale_code in local_codes_to_use do
            if translation.locale['code'].eql?(locale_code)
              translation_hash[attribute] = translation.content
            end
          end
        end
      end
    end
  end

  def get_all_translations
    translations = []

    locales.each do |locale|
      next if locale === Translatable::DEFAULT_LOCALE
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

  def push_locale_file(file, locale_id, tags: nil)
    begin
      params = PhraseApp::RequestParams::UploadParams.new(
        file: file.path,
        update_translations: true,
        tags: tags || '',
        encoding: 'UTF-8',
        file_format: 'nested_json',
        locale_id: locale_id
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

  def locale_id(locale)
    @locales[locale].try(:id) || raise("locale #{locale} could not be found in list of locales: #{@locales.keys}")
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

  def delete_unused_keys(dry_run: true)
    begin
      json = download_locale(Translatable::DEFAULT_LOCALE, true)
      event_ids = json['event'].try(:keys) || []
      orga_ids = json['orga'].try(:keys) || []

      keys_to_destroy =
        get_keys_to_destroy(Orga, orga_ids) +
          get_keys_to_destroy(Event, event_ids)

      if dry_run
        Rails.logger.info 'would delete the following keys:'
        Rails.logger.info keys_to_destroy.join("\n")
      else
        deleted = 0
        keys_to_destroy.each do |key|
          params = PhraseApp::RequestParams::KeysDeleteParams.new(q: key)
          affected = @client.keys_delete(@project_id, params).first.records_affected
          deleted = deleted + affected
        end
        Rails.logger.debug "deleted #{deleted} keys."
      end
    rescue => exception
      Rails.logger.error 'error for delete_all_keys_not_used_in_database'
      Rails.logger.error exception.message
      Rails.logger.error exception.backtrace.join("\n")
      raise exception unless Rails.env.production?
    end
  end

  private

  def download_locale(locale_id, include_empty_translations = false)
    params = PhraseApp::RequestParams::LocaleDownloadParams.new(
      file_format: 'nested_json',
      encoding: 'UTF-8'
    )
    json = @client.locale_download(@project_id, locale_id, params).force_encoding('UTF-8')
    return JSON.parse json
  end

  def initialize_locales_for_project
    @locales = {}
    @client.locales_list(@project_id, 1, 100)[0].each do |locale|
      @locales[locale.code] = locale
    end
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

  def create_translation_for_key(key_id, locale, content)
    params =
      PhraseApp::RequestParams::TranslationParams.new(
        locale_id: locale_id(locale),
        content: content.to_s,
        key_id: key_id)
    @client.translation_create(@project_id, params)
  end

  def update_translation_for_translation_id(translation_id, content)
    params = PhraseApp::RequestParams::TranslationUpdateParams.new(content: content.to_s)
    @client.translation_update(@project_id, translation_id, params)
  end

  def find_key_id_by_key_name(keyname)
    params = PhraseApp::RequestParams::KeysSearchParams.new(q: keyname)
    response = @client.keys_search(@project_id, 1, 100, params)
    response[0][0].try(:id)
  end

  def create_key(keyname)
    params = PhraseApp::RequestParams::TranslationKeyParams.new(name: keyname)
    response = @client.key_create(@project_id, params)
    response[0].try(:id) || raise("could not create key #{keyname}")
  end

  def find_translation_id_by_key_id_and_locale(key_id, locale)
    params = PhraseApp::RequestParams::TranslationsByKeyParams.new()
    available_translations = @client.translations_by_key(@project_id, key_id, 1, 100000, params)[0]
    for translation in available_translations do
      if translation.locale['code'].eql?(locale)
        return translation.id
      end
    end
    nil
  end
end
