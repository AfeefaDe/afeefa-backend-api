class TranslationCache < ApplicationRecord

  def self.rebuild_db_cache!(translations)
    TranslationCache.delete_all

    num = 0

    translations.each do |translation|
      cached_entry =
        TranslationCache.find_by(
          cacheable_id: translation[:id],
          cacheable_type: translation[:type].capitalize,
          language: translation[:language]
        ) ||
          TranslationCache.new(
            cacheable_id: translation[:id],
            cacheable_type: translation[:type].capitalize,
            language: translation[:language]
          )

      cached_entry.send("#{translation[:key]}=", translation[:content])

      cached_entry.save!

      num += 1
    end
    num
  end
end
