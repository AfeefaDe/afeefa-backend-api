module Neos
  module Migration

    class << self
      def migrate
        Neos::Category.where(locale: :de).limit(10).each do |category|
          next if ::Category.find_by_title(category.name)
          new_category = ::Category.new(
            title: category.name,
            is_sub_category: false
          )
          unless new_category.save
            puts "Category is not valid, but we will save it. Errors: #{new_category.errors.full_messages}"
            new_category.save(validate: false)
          end
        end

        Neos::Orga.where(locale: :de).limit(10).each do |orga|
          create_entry_and_handle_validation(orga) do
            ::Orga.new(
              title: orga.name,
              description: orga.description,
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
        end

        Neos::Event.where(locale: :de).limit(10).each do |event|
          create_entry_and_handle_validation(event) do
            type_datetime_from =
              parse_datetime_and_return_type(:date_start, event.datefrom, event.timefrom)
            type_datetime_to =
              parse_datetime_and_return_type(
                :date_end,
                event.dateto.present? ? event.dateto : event.datefrom, event.timeto)
            ::Event.new(
              title: event.name,
              description: event.description,
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
              creator: User.first # assume that this is the system user
            )
          end
        end
      end

      private

      def parse_datetime_and_return_type(attribute, date_string, time_string)
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
          puts "Failed to parse datetime for #{attribute}, given: #{date_string} #{time_string}"
          datetime = parse_date(date_string)
          type = :date
          [datetime, type]
        rescue ArgumentError => _exception
          puts "Failed to parse date for #{attribute}, given: #{date_string} #{time_string}"
          [nil, nil]
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
          (orgas = ::Orga.where(title: parent.name)) &&
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
            lat: location['lat'],
            lon: location['lon'],
            street: location['street'],
            # TODO: Should we auto regex the number from
            # number: 'Die Hausnummer steht aktuell in der Straße mit drin.',
            placename: location['placename'],
            zip: location['zip'],
            city: location['city'],
            district: location['district'],
            state: 'Sachsen',
            country: 'Deutschland',
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
            mail: entry.mail,
            phone: entry.phone,
            contact_person: entry.speakerpublic
          )
        unless new_contact_info.save
          create_annotations(new_entry, new_contact_info.errors.full_messages)
        end
      end

      def create_annotations(new_entry, details)
        [details].flatten.each do |detail|
          annotation =
            AnnotationAbleRelation.new(
              entry: new_entry,
              annotation: Annotation.where('title LIKE ?', 'Migration nur teilweise erfolgreich').first,
              detail: detail
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
