module Dev
  module SeedPhraseapp

    # use this task via 'rails c' to reset the phraseapp test account to a fresh state
    # jes 30.03.2018

    class << self
      def seed_now
        client = PhraseAppClient.new

        puts 'Cleaning up phraseapp.'
        delete_count = client.delete_all_keys
        puts "Cleaned up phraseapp. Deleted #{delete_count} keys."

        orgas = Orga.all
        events = Event.all
        entries = orgas + events

        facet_items = DataPlugins::Facet::FacetItem.all
        navigation_items = DataModules::FeNavigation::FeNavigationItem.all
        facet_and_navigation_items = facet_items + navigation_items

        locales = [Translatable::DEFAULT_LOCALE] + Translatable::TRANSLATABLE_LOCALES
        locales.each do |locale|
          translation_hash = {
            event: {},
            orga: {},
            facet_item: {},
            navigation_item: {}
          }

          entries.each do |entry|
            if (locale == Translatable::DEFAULT_LOCALE or rand(100) == 0) # not de => translate randomly 1 percent
              type = entry.is_a?(Event) ? :event : :orga

              if !entry.title.blank? || !entry.short_description.blank?
                translation_hash[type][entry.id] = {}
                if !entry.title.blank?
                  title = locale == Translatable::DEFAULT_LOCALE ? entry.title : "#{type}.#{entry.id}.title.#{locale}"
                  translation_hash[type][entry.id][:title] = title
                end
                if !entry.short_description.blank?
                  short_description = locale == Translatable::DEFAULT_LOCALE ? entry.short_description : "#{type}.#{entry.id}.short_description.#{locale}"
                  translation_hash[type][entry.id][:short_description] = short_description
                end
              end
            end
          end

          facet_and_navigation_items.each do |item|
            if (locale == Translatable::DEFAULT_LOCALE or rand(100) == 0) # not de => translate randomly 1 percent
                type = item.is_a?(DataPlugins::Facet::FacetItem) ? :facet_item : :navigation_item

              if !item.title.blank?
                translation_hash[type][item.id] = {}
                title = locale == Translatable::DEFAULT_LOCALE ? item.title : "#{type}.#{item.id}.title.#{locale}"
                translation_hash[type][item.id][:title] = title
              end
            end
          end

          translation_file_name = "translation-new-#{locale}-"
          file = Tempfile.new([translation_file_name, '.json'], encoding: 'UTF-8')
          file.write(JSON.pretty_generate(translation_hash))
          file.close

          puts "created file #{file.path}"

          client.upload_translation_file_for_locale(file, locale)

          puts "pushed file #{file.path}"
        end

        puts "tag all areas"
        client.tag_all_areas
        puts "all areas tagged"
      end

    end
  end
end