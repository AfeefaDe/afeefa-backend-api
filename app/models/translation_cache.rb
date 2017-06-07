class TranslationCache < ApplicationRecord

  def self.rebuild_db_cache!(translations)
    TranslationCache.delete_all

    num = 0
    translations.each do |translation|
      if translation.is_a?(PhraseApp::ResponseObjects::Translation) &&
          translation.locale['code'] != Translatable::DEFAULT_LOCALE

        decoded_key = client.decode_key(translation.key['name'])

        cached_entry =
          TranslationCache.find_by(
            cacheable_id: decoded_key[:id],
            cacheable_type: decoded_key[:model],
            language: translation.locale['code']
          ) ||
            TranslationCache.new(
              cacheable_id: decoded_key[:id],
              cacheable_type: decoded_key[:model],
              language: translation.locale['code']
            )

        cached_entry.send("#{decoded_key[:attribute]}=", translation.content)

        cached_entry.save!

        num += 1
      end
    end
    num
  end

end
