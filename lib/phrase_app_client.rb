require 'phraseapp-ruby'

class PhraseAppClient

  def initialize(project_id: nil, token: nil)
    @project_id =
        project_id ||
            if Rails.env.production?
              Settings.phraseapp.project_id
            elsif Rails.env.development?
              Settings.phraseapp.dev_project_id
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
        key = "#{model.class.to_s.underscore}.#{model.id}.#{attribute}"
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

  def delete_translation(model)
    model.class.translatable_attributes.each do |attribute|
      key = "#{model.class.to_s.underscore}.#{model.id}.#{attribute}"
      key_id = find_key_id_by_key_name(key)
      next unless key_id

      @client.key_delete(@project_id, key_id)
    end
  end

  def get_translation(model, locale, fallback: true)
    {}.tap do |translation_hash|
      model.class.translatable_attributes.each do |attribute|
        key =
            if model.class.to_s.start_with?('Neos::')
              "entry.#{model.entry_id}.#{attribute}"
            else
              "#{model.class.to_s.underscore}.#{model.id}.#{attribute}"
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
    params = PhraseApp::RequestParams::TranslationsListParams.new
    page = 1
    translations = []
    loop do
      t = @client.translations_list(@project_id, page, 100, params)
      break if t[0].empty?
      translations += t[0]
      page += 1
    end
    translations
  end

  private

  def initialize_locales_for_project
    @locales = {}
    @client.locales_list(@project_id, 1, 100)[0].each do |locale|
      @locales[locale.code] = locale
    end
  end

  def locale_id(locale)
    @locales[locale].try(:id) || raise('invalid locale')
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
    params = PhraseApp::RequestParams::KeysSearchParams.new(:q => keyname)
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

  def delete_all_keys
    begin
      params = PhraseApp::RequestParams::KeysDeleteParams.new(q: '*')
      @client.keys_delete(@project_id, params).first.records_affected
    rescue => exception
      message = 'Could not delete all keys for '
      message << "the following error: #{exception.message}\n"
      message << "#{exception.backtrace[0..14].join("\n")}"
      logger.error message
      raise message if Rails.env.development?
    end
  end

end
