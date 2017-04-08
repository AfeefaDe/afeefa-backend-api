module Neos
  module Migration

    class << self
      def migrate
        puts "Step 1: Migrating #{Neos::Category.where(locale: :de).count} categories"
        count = 0
        Neos::Category.where(locale: :de).each do |category|
          next if ::Category.find_by_title(category.name)
          new_category = ::Category.new(title: category.name.try(:strip))
          unless new_category.save
            puts "Category is not valid, but we will save it. Errors: #{new_category.errors.full_messages}"
            new_category.save(validate: false)
          end
          puts "#{count += 1} categories processed"
        end

        puts "Step 2: Migrating #{Neos::Orga.where(locale: :de).count} orgas"
        count = 0
        Neos::Orga.where(locale: :de).each do |orga|
          create_entry_and_handle_validation(orga) do
            ::Orga.new(
              title: orga.name.try(:strip),
              description: orga.description.try(:strip) || '',
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
          puts "#{count += 1} orgas processed"
        end

        puts "Step 3: Migrating #{Neos::Event.where(locale: :de).count} events"
        count = 0
        Neos::Event.where(locale: :de).each do |event|
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
          puts "#{count += 1} events processed"
        end

        puts "Migration finished."
      end

      private

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
        new_entry = yield
        unless new_entry.valid?
          unless new_entry.save
            unless new_entry.save(validate: false)
              fail "Entry not creatable: #{new_entry.errors.messages}"
            end
            create_annotations(new_entry, new_entry.errors.full_messages)
          end
          if new_entry.errors.key?(:category)
            create_annotations(new_entry, "Kategorie fehlerhaft: #{new_entry.category} ist nicht erlaubt.")
          end
          entry.locations.each do |location|
            create_location(new_entry, location)
          end
          create_contact_info(new_entry, entry)
        end
      rescue => exception
        puts '-------------------------------------------------------'
        puts "Entry could not be created for the following exception: #{exception.class}: #{exception.message}"
        puts 'Backtrace:'
        puts exception.backtrace.join("\n")
      end

      def create_location(new_entry, location)
        new_location =
          ::Location.new(
            locatable: new_entry,
            lat: location['lat'].try(:strip),
            lon: location['lon'].try(:strip),
            street: location['street'].try(:strip),
            # TODO: Should we auto regex the number from
            # number: 'Die Hausnummer steht aktuell in der Straße mit drin.',
            placename: location['placename'].try(:strip),
            zip: location['zip'].try(:strip),
            city: location['city'].try(:strip),
            district: location['district'].try(:strip),
            state: 'Sachsen',
            country: 'Deutschland',
            migrated_from_neos: true,
          )
        unless new_location.save
          create_annotations(new_entry, new_location.errors.full_messages)
        end
        if new_location.number.blank?
          create_annotations(new_entry, 'Hausnummer fehlt')
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
            migrated_from_neos: true,
          )
        unless new_contact_info.save
          create_annotations(new_entry, new_contact_info.errors.full_messages)
        end
      end

      def create_annotations(new_entry, details)
        [details].flatten.each do |detail|
          annotation =
            Todo.new(
              entry: new_entry,
              annotation: Annotation.where('title LIKE ?', 'Migration nur teilweise erfolgreich').first,
              detail: detail.try(:strip)
            )
          unless annotation.save
            puts "Annotation is not valid, but we will save it. Errors: #{annotation.errors.full_messages}"
            annotation.save(validate: false)
          end
        end
      end
    end
  end
end
