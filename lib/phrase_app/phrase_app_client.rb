require 'phraseapp-ruby'

module PhraseApp
  class PhraseAppClient
    PROJECTID = "3746daa3615235f8a940868010fecb44"
    TOKEN = "17f10e70ea0f09650b3d8d3a734554f907d4bfa661799adaca106fe47a45378b"
    attr_reader :client
    attr_accessor :locales
    FALLBACK_LIST = []#[:de]

    def initialize
      credentials = PhraseApp::Auth::Credentials.new(token: TOKEN)
      @client = PhraseApp::Client.new(credentials)
      self.locales = {}
      initialize_locales_for_project
      #puts locales.inspect
    end

    def initialize_locales_for_project
      client.locales_list(PROJECTID, 1, 10000)[0].each do |locale|
        locales[locale.code] = locale
      end
    end

    def create_translation(model, locale)
      locale_id = locales[locale].id
      key = "#{model.class.to_s.underscore}.#{model.id}.name"
      params = PhraseApp::RequestParams::TranslationKeyParams.new(:name => key)
      response = client.key_create(PROJECTID, params)
      puts response.last.inspect
      key_id = response[0].id
      params = PhraseApp::RequestParams::TranslationParams.new(:locale_id => "de", :content => model.title, :key_id => key_id)
      client.translation_create(PROJECTID, params)
    end

    def get_translation(model, locale)
      # locale.model.id.attribut
      key = "#{model.class.to_s.underscore}.#{model.id}.name"
      key_id = find_key_id_by_key_name(key)
      params = PhraseApp::RequestParams::TranslationsByKeyParams.new()
      available_translations = client.translations_by_key(PROJECTID, key_id, 1, 100000, params)[0]

      if FALLBACK_LIST.include?(locale) == false
        FALLBACK_LIST.unshift(locale)
      end
      puts FALLBACK_LIST
      for translation in available_translations do
        for locale_code in FALLBACK_LIST do
          puts locale_code
          puts translation.locale["code"]
          if translation.locale["code"].eql?(locale_code)
            return translation
          end
        end
      end
      #return available_translations
    end

    def find_key_id_by_key_name(keyname)
      params = PhraseApp::RequestParams::KeysSearchParams.new(:q => keyname)
      response = client.keys_search(PROJECTID, 1, 100000, params)
      return response[0][0].id
    end

  end
end
