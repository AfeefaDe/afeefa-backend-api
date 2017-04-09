module Neos
  module Migration

    class << self
      def migrate(migrate_phraseapp: false, limit: {})
        limit = limit || {}
        @migrate_phraseapp = migrate_phraseapp

        puts "Start Migration of Afeefa.de live data (#{Time.current.to_s})"

        count = 0
        categories = Neos::Category.where(locale: :de).limit(limit[:categories])
        puts "Step 1: Migrating #{categories.count} categories (#{Time.current.to_s})"
        categories.each do |category|
          next if ::Category.find_by_title(category.name)
          new_category = ::Category.new(title: category.name.try(:strip))
          unless new_category.save
            puts "Category is not valid, but we will save it. Errors: #{new_category.errors.full_messages}"
            new_category.save(validate: false)
          end
          puts_process(type: 'categories', processed: count += 1, all: categories.count)
        end

        count = 0
        orgas = Neos::Orga.where(locale: :de).limit(limit[:orgas])
        puts "Step 2: Migrating #{orgas.count} orgas (#{Time.current.to_s})"
        orgas.each do |orga|
          create_entry_and_handle_validation(orga) do
            ::Orga.new(
              title: orga.name.try(:strip),
              description: orga.description.try(:strip) || '',
              short_description: orga.try(:descriptionshort).try(:strip) || '',
              media_url: orga.image.try(:strip),
              media_type: orga.imagetype.try(:strip), # image | youtube
              support_wanted: orga.supportwanted,
              for_children: orga.forchildren,
              certified_sfr: orga.certified,
              legacy_entry_id: orga.entry_id.try(:strip),
              migrated_from_neos: true,
              sub_category:
                if orga.subcategory
                  ::Category.find_by_title(orga.subcategory)
                end,
              category:
                if orga.category
                  ::Category.find_by_title(orga.category.name)
                end,
              parent: parent_or_root_orga(orga.parent)
            )
          end
          puts_process(type: 'orgas', processed: count += 1, all: orgas.count)
        end

        count = 0
        events = Neos::Event.where(locale: :de).limit(limit[:events])
        puts "Step 3: Migrating #{events.count} events (#{Time.current.to_s})"
        events.each do |event|
          create_entry_and_handle_validation(event) do
            type_datetime_from =
              parse_datetime_and_return_type(:date_start, event.datefrom, event.timefrom)
            type_datetime_to =
              parse_datetime_and_return_type(
                :date_end,
                event.dateto.present? ? event.dateto : event.datefrom, event.timeto)
            if type_datetime_from.first.nil? || type_datetime_from.last.nil?
              puts "failing on parsing date or time for event: #{event.inspect}"
            end
            ::Event.new(
              title: event.name.try(:strip),
              description: event.description.try(:strip) || '',
              short_description: event.try(:descriptionshort).try(:strip) || '',
              media_url: event.image.try(:strip),
              media_type: event.imagetype.try(:strip), # image | youtube
              support_wanted: event.supportwanted,
              for_children: event.forchildren,
              certified_sfr: event.certified,
              legacy_entry_id: event.entry_id.try(:strip),
              migrated_from_neos: true,
              sub_category:
                if event.subcategory
                  ::Category.find_by_title(event.subcategory)
                end,
              category:
                if event.category
                  ::Category.find_by_title(event.category.name)
                end,
              date_start: type_datetime_from[0],
              date_end: type_datetime_to[0],
              time_start: type_datetime_from[1] == :datetime,
              time_end: type_datetime_to[1] == :datetime,
              orga: parent_or_root_orga(event.parent),
              creator: User.first # TODO: assume that this is the system user → Is it?
            )
          end
          puts_process(type: 'events', processed: count += 1, all: events.count)
        end

        puts "Migration finished (#{Time.current.to_s})."
        puts "Categories: IS: #{::Category.count}, SHOULD: #{categories.count} " +
          '(sub categories where former strings)'
        puts "Orgas:: IS: #{::Orga.count}, SHOULD: #{orgas.count}"
        puts "Events: IS: #{::Event.count}, SHOULD: #{events.count}"
      end

      private

      def migrate_phraseapp_data(entry, new_entry)
        @client_old ||=
          PhraseAppClient.new(
            project_id: Settings.migration.phraseapp.project_id, token: Settings.migration.phraseapp.token)
        @client_new ||= PhraseAppClient.new
        responses = []

        @client_old.locales.each do |locale|
          next if locale == Translatable::DEFAULT_LOCALE

          translated_attributes =
            @client_old.get_translation(entry, locale, fallback: false)
          if translated_attributes[:name].present?
            translated_attributes[:title] = translated_attributes.delete(:name)
          end

          if translated_attributes.present? && translated_attributes.keys.any?
            new_entry.attributes = translated_attributes
            responses << @client_new.create_or_update_translation(new_entry, locale)
          end
        end
        responses
      end

      def puts_process(type:, processed:, all:)
        puts "processed #{processed} of #{all} #{type}: #{'%.2f' % (processed.to_f/all*100)}%"
      end

      def parse_datetime_and_return_type(attribute, date_string, time_string)
        date_string = date_string
        if date_string.strip =~ /\Ad{4}\z/
          puts "date_string #{attribute} is a year, we assume 01.01.#{date_string}"
          date_string = "#{date_string}-01-01"
        end
        begin
          datetime = nil
          type = nil
          if time_string.present?
            datetime = parse_datetime(date_string, time_string)
            type = :datetime
            [datetime, type]
          else
            datetime = parse_date(date_string)
            type = :date
            [datetime, type]
          end
        rescue ArgumentError => _exception
          begin
            puts "Failed to parse datetime for #{attribute}, given: #{date_string} #{time_string}"
            datetime = parse_date(date_string)
            type = :date
            [datetime, type]
          rescue ArgumentError => _exception
            puts "Failed to parse date for #{attribute}, given: #{date_string} #{time_string}"
            [nil, nil]
          end
        end
      end

      def parse_datetime(date_string, time_string)
        datetime_string = "#{date_string} #{time_string}"
        Time.zone.parse(datetime_string)
      end

      def parse_date(date_string)
        datetime_string = "#{date_string}"
        Time.zone.parse(datetime_string)
      end

      def parent_or_root_orga(parent)
        if parent && parent.orga? &&
          (orgas = ::Orga.where(title: parent.name.try(:strip))) &&
          (orgas.count == 1)
          orgas.first
        else
          ::Orga.root_orga
        end
      end

      def create_entry_and_handle_validation(entry)
        # puts "migrating entry '#{entry.name}'"
        new_entry = yield

        new_entry.skip_phraseapp_translations! unless @migrate_phraseapp

        if new_entry.save
          # puts "saved valid entry '#{new_entry.title}'"
        else
          # binding.pry if new_entry.title.blank?
          if new_entry.save(validate: false)
            # puts "saved invalid entry '#{new_entry.title}'"
          else
            puts "Entry not creatable: #{new_entry.errors.messages}"
          end
          create_annotations(new_entry, new_entry.errors.full_messages)
        end
        if new_entry.errors.key?(:category)
          create_annotations(new_entry, "Kategorie fehlerhaft: #{new_entry.category} ist nicht erlaubt.")
        end
        # puts "entry #{new_entry.class.to_s} with title '#{new_entry.title}' processed, " +
        #   "new #{new_entry.class.to_s} count: #{new_entry.class.count}"
        entry.locations.each do |location|
          create_location(new_entry, location)
        end
        create_contact_info(new_entry, entry)

        if new_entry.persisted? && @migrate_phraseapp
          migrate_phraseapp_data(entry, new_entry)
        end
      rescue => exception
        puts '-------------------------------------------------------'
        puts "Entry could not be created for the following exception: #{exception.class}: #{exception.message}"
        puts 'Backtrace:'
        puts exception.backtrace[0..14].join("\n")
      end

      def create_location(new_entry, location)
        new_location =
          ::Location.new(
            locatable: new_entry,
            lat: location['lat'].try(:strip),
            lon: location['lon'].try(:strip),
            street: location['street'].try(:strip),
            placename: location['placename'].try(:strip),
            zip: location['zip'].try(:strip),
            city: location['city'].try(:strip),
            directions: location['arrival'].try(:strip),
            migrated_from_neos: true,
          )
        unless new_location.save
          create_annotations(new_entry, new_location.errors.full_messages)
        end
      end

      def create_contact_info(new_entry, entry)
        new_contact_info =
          ContactInfo.new(
            contactable: new_entry,
            web: entry.web.try(:strip),
            facebook: entry.facebook.try(:strip),
            spoken_languages: entry.spokenlanguages.try(:strip),
            mail: entry.mail.try(:strip),
            phone: entry.phone.try(:strip),
            contact_person: entry.speakerpublic.try(:strip),
            opening_hours: entry.locations.first.try(:opening_hours).try(:strip),
            migrated_from_neos: true,
          )
        unless new_contact_info.save
          create_annotations(new_entry, new_contact_info.errors.full_messages)
        end
      end

      def create_annotations(new_entry, details)
        [details].flatten.each do |detail|
          todo =
            Todo.new(
              entry: new_entry,
              annotation: Annotation.where('title LIKE ?', 'Migration nur teilweise erfolgreich').first,
              detail: detail.try(:strip)
            )
          unless todo.save
            puts "Todo is not valid, but we will save it. Errors: #{todo.errors.full_messages}"
            todo.save(validate: false)
          end
        end
      end
    end

  end
end
