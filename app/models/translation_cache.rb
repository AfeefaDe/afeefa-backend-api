class TranslationCache < ApplicationRecord

  def self.rebuild_db_cache!(translations)
    TranslationCache.delete_all

    num = 0
    translations.each do |translation|
      if translation.is_a?(PhraseApp::ResponseObjects::Translation) &&
          translation.locale['code'] != Translatable::DEFAULT_LOCALE

       decoded_key = translation.key['name'].split('.')

        cached_entry =
          TranslationCache.find_by(
            cacheable_id: decoded_key[1],
            cacheable_type: decoded_key[0],
            language: translation.locale['code']
          ) ||
            TranslationCache.new(
              cacheable_id: decoded_key[1],
              cacheable_type: decoded_key[0],
              language: translation.locale['code']
            )

        cached_entry.send("#{decoded_key[2]}=", translation.content)

        cached_entry.save!

        num += 1
      end
    end
    num
  end
end
