module Neos
  module Migration

    class << self
      def migrate
        Neos::Category.where(locale: :de).each do |category|
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

        Neos::Orga.where(locale: :de).each do |orga|
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

        Neos::Event.where(locale: :de).each do |event|
          create_entry_and_handle_validation(event) do
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
              date_start: Time.zone.parse("#{event.datefrom} #{event.timefrom}"),
              date_end: Time.zone.parse("#{event.dateto} #{event.timeto}"),
              orga: parent_or_root_orga(event.parent),
              creator: User.first # assume that this is the system user
            )
          end
        end
      end

      private

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
        puts "Entry could not be created for the following exception: #{exception.message}"
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
