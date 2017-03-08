require 'phraseapp-ruby'

class PhraseAppClient
  attr_reader :client

  def initialize
    @project_id = Settings.phraseapp.project_id || ''
    @token = Settings.phraseapp.api_token || ''
    @fallback_list = Settings.phraseapp.fallback_list || []

    credentials = PhraseApp::Auth::Credentials.new(token: @token)
    @client = PhraseApp::Client.new(credentials)
    initialize_locales_for_project
  end

  def initialize_locales_for_project
    @locales = {}
    client.locales_list(@project_id, 1, 10000)[0].each do |locale|
      @locales[locale.code] = locale
    end
  end

  def create_translation(model, locale)
    locale_id = @locales[locale].id

    model.class.translatable_attributes.each do |attribute|
      key = "#{model.class.to_s.underscore}.#{model.id}.#{attribute}"
      params = PhraseApp::RequestParams::TranslationKeyParams.new(name: key)
      response = client.key_create(@project_id, params)
      key_id = response[0].id
      params =
        PhraseApp::RequestParams::TranslationParams.new(
          locale_id: locale_id || 'de',
          content: model.send(attribute).to_s,
          key_id: key_id)
      client.translation_create(@project_id, params)
    end
  end

  def delete_translation(model)
    model.class.translatable_attributes.each do |attribute|
      key = "#{model.class.to_s.underscore}.#{model.id}.#{attribute}"
      key_id = find_key_id_by_key_name(key)
      next unless key_id

      client.key_delete(@project_id, key_id)
    end
  end

  def get_translation(model, locale, fallback: true)
    {}.tap do |translation_hash|
      model.class.translatable_attributes.each do |attribute|
        key = "#{model.class.to_s.underscore}.#{model.id}.#{attribute}"
        key_id = find_key_id_by_key_name(key)
        next unless key_id

        params = PhraseApp::RequestParams::TranslationsByKeyParams.new()
        available_translations = client.translations_by_key(@project_id, key_id, 1, 100000, params)[0]

        unless @fallback_list.include?(locale)
          @fallback_list.unshift(locale)
        end
        for translation in available_translations do
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

  def find_key_id_by_key_name(keyname)
    params = PhraseApp::RequestParams::KeysSearchParams.new(:q => keyname)
    response = client.keys_search(@project_id, 1, 100000, params)
    return response[0][0].try(:id)
  end

end
