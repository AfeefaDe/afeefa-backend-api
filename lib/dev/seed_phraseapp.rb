module Dev
  module SeedPhraseapp

    class << self
      def seed_now
        client = PhraseAppClient.new

        puts 'Cleaning up phraseapp.'
        delete_count = client.delete_all_keys
        puts "Cleaned up phraseapp. Deleted #{delete_count} keys."

        orgas = Orga.all
        events = Event.all
        entries = orgas + events

        locales = [Translatable::DEFAULT_LOCALE] + Translatable::TRANSLATABLE_LOCALES
        locales.each do |locale|
          translation_hash = {
            event: {},
            orga: {}
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

          translation_file_name = "translation-new-#{locale}-"
          file = Tempfile.new([translation_file_name, '.json'], encoding: 'UTF-8')
          file.write(JSON.pretty_generate(translation_hash))
          file.close

          puts "created file #{file.path}"

          client.upload_translation_file_for_locale(file, locale)

          puts "pushed file #{file.path}"
        end


      end

    end
  end
end