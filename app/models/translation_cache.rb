class TranslationCache < ApplicationRecord

  def self.phraseapp_entry_params_to_entry(type, id)
    entry = nil
    case type
    when 'orga'
      entry = Orga.find_by(id: id)
    when 'event'
      entry = Event.find_by(id: id)
    when 'offer'
      entry = DataModules::Offer::Offer.find_by(id: id)
    when 'facet_item'
      entry = DataPlugins::Facet::FacetItem.find_by(id: id)
    when 'navigation_item'
      entry = DataModules::FeNavigation::FeNavigationItem.find_by(id: id)
    end
    entry
  end

  def self.rebuild_db_cache!(translations)
    TranslationCache.delete_all

    num = 0

    translations.each do |translation|
      entry = TranslationCache.phraseapp_entry_params_to_entry(translation[:type], translation[:id])

      if entry
        cached_entry =
          TranslationCache.find_by(
            cacheable_id: entry.id,
            cacheable_type: entry.class.name,
            language: translation[:language]
          ) ||
            TranslationCache.new(
              cacheable_id: entry.id,
              cacheable_type: entry.class.name,
              language: translation[:language]
            )

        cached_entry.send("#{translation[:key]}=", translation[:content])

        cached_entry.save!

        num += 1
      end
    end
    num
  end
end
