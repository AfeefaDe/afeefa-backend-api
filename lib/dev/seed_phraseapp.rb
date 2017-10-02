module Dev
  module SeedPhraseapp

    class << self
      def seed_now
        client = PhraseAppClient.new(
          project_id: Settings.phraseapp.test_project_id,
          token: Settings.phraseapp.api_token
        )

        puts 'Cleaning up phraseapp.'
        delete_count = client.delete_all_keys
        puts "Cleaned up phraseapp. Deleted #{delete_count} keys."

        orgas = Orga.all

        client.locales.each_with_index do |locale, index|
          translation_hash = {
            event: {},
            orga: {}
          }

          orgas.each do |orga|
            title = locale === 'de' ? orga.title : "orga.#{orga.id}.title.#{locale}"
            short_description = locale === 'de' ? orga.short_description : "orga.#{orga.id}.short_description.#{locale}"

            translation_hash[:orga][orga.id] = {
              title: title,
              short_description: short_description
            }
          end

          phraseapp_translations_dir = Rails.root.join('tmp', 'translations')
          FileUtils.mkdir_p(phraseapp_translations_dir)
          phraseapp_translations_file_path =
            File.join(phraseapp_translations_dir, "translation-new-#{locale}.json")
          file = File.new(phraseapp_translations_file_path, 'w:UTF-8')
          file.write(JSON.pretty_generate(translation_hash))
          file.close

          puts "created file #{phraseapp_translations_file_path}"

          client.push_locale_file(file.path, client.locale_id(locale))

          puts "pushed file #{phraseapp_translations_file_path}"
        end


      end

    end
  end
end