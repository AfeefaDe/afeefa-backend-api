module Neos
  module Migration

    class << self
      def migrate
        Neos::Orga.where(locale: :de).each do |orga|
          create_entry_and_handle_validation(orga) do
            ::Orga.new(
              title: orga.name,
              description: orga.description,
              category: orga.subcategory || orga.category && orga.category.name,
              parent: parent_or_root_orga(orga.parent)
            )
          end
        end

        Neos::Event.where(locale: :de).each do |event|
          create_entry_and_handle_validation(event) do
            ::Event.new(
              title: event.name,
              description: event.description,
              category: event.subcategory || event.category && event.category.name,
              date: event.datefrom,
              orga: parent_or_root_orga(event.parent)
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
          if new_entry.errors.key?(:category)
            create_annotations(new_entry, "Kategorie fehlerhaft: #{new_entry.category} ist nicht erlaubt.")
          end
          if new_entry.title.size > 254
            create_annotations(new_entry, 'Der Titel ist länger als 255 Zeichen und wurde abgeschnitten.')
            new_entry.title = new_entry.title[0..254]
          end
          if new_entry.description.size > 254
            create_annotations(new_entry, 'Die Beschreibung ist länger als 255 Zeichen und wurde abgeschnitten.')
            new_entry.description = new_entry.description[0..254]
          end
          unless new_entry.save
            unless new_entry.save(validate: false)
              raise "Entry not creatable: #{new_entry.errors.messages}"
            end
            create_annotations(new_entry, new_entry.errors.full_messages)
          end
          entry.locations.each do |location|
            create_location(new_entry, location)
          end
          create_contact_info(new_entry, entry)
        end
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
        if new_location.number.blank?
          create_annotations(new_entry, 'Hausnummer fehlt')
        end
        unless new_location.save
          create_annotations(new_entry, new_location.errors.full_messages)
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

      def create_annotations(new_entry, titles)
        [titles].flatten.each do |title|
          annotation =
            Annotation.new(
              annotatable: new_entry,
              title: title[0..254]
            )
          unless annotation.save
            pp "Annotation is not valid, but we will save it. Errors: #{annotation.errors.full_messages}"
            annotation.save(validate: false)
          end
        end
      end
    end
  end
end
