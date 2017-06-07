module Neos
  module Migration

    # CONSTANTS
    SUB_CATEGORIES =
      # mapping for subcategories given by old frontend
      {
        general: [
          { name: 'wifi', id: '0-1' },
          { name: 'jewish', id: '0-2' },
          { name: 'christian', id: '0-3' },
          { name: 'islam', id: '0-4' },
          { name: 'religious-other', id: '0-5' },
          { name: 'shop', id: '0-6' },
          { name: 'nature', id: '0-7' },
          { name: 'authority', id: '0-8' },
          { name: 'hospital', id: '0-9' },
          { name: 'police', id: '0-10' },
          { name: 'public-transport', id: '0-11' }
        ],
        language: [
          { name: 'german-course', id: '1-1' },
          { name: 'interpreter', id: '1-2' },
          { name: 'learning-place', id: '1-3' },
          { name: 'tandem', id: '1-4' }
        ],
        medic: [
          { name: 'medical-counselling', id: '2-1' },
          { name: 'medical-care', id: '2-2' },
          { name: 'psychological-counselling', id: '2-3' }
        ],
        jobs: [
          { name: 'job-counselling', id: '3-1' },
          { name: 'education-counselling', id: '3-2' },
          { name: 'political-education', id: '3-3' },
          { name: 'education-sponsorship', id: '3-4' },
          { name: 'library', id: '3-5' }
        ],
        consultation: [
          { name: 'asylum-counselling', id: '4-1' },
          { name: 'legal-advice', id: '4-2' },
          { name: 'social-counselling', id: '4-3' },
          { name: 'family-counselling', id: '4-4' },
          { name: 'women-counselling', id: '4-5' },
          { name: 'volunteer-coordination', id: '4-6' }
        ],
        leisure: [
          { name: 'youth-club', id: '5-1' },
          { name: 'sports', id: '5-2' },
          { name: 'museum', id: '5-3' },
          { name: 'music', id: '5-4' },
          { name: 'stage', id: '5-5' },
          { name: 'craft-art', id: '5-6' },
          { name: 'gardening', id: '5-7' },
          { name: 'cooking', id: '5-8' },
          { name: 'festival', id: '5-9' },
          { name: 'lecture', id: '5-10' }
        ],
        community: [
          { name: 'welcome-network', id: '6-1' },
          { name: 'meeting-place', id: '6-2' },
          { name: 'childcare', id: '6-3' },
          { name: 'workshop', id: '6-4' },
          { name: 'sponsorship', id: '6-5' },
          { name: 'lgbt', id: '6-6' },
          { name: 'housing-project', id: '6-7' }
        ],
        donation: [
          { name: 'food', id: '7-1' },
          { name: 'clothes', id: '7-2' },
          { name: 'furniture', id: '7-3' }
        ],
        eventseries: [
          { name: 'iwgr', id: '8-1' },
          { name: 'political-education', id: '8-2' }
        ]
      }

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
            build_orga_from_neos_orga(orga)
          end
          puts_process(type: 'orgas', processed: count += 1, all: orgas.count)
        end

        count = 0
        childorgas = Neos::Orga.where(locale: :de).where.not(parent_entry_id: nil).limit(limit[:orgas])
        puts "Step 2b: Setting parent to #{childorgas.count} child orgas (#{Time.current.to_s})"
        childorgas.each do |orga|
          set_parent_orga_to_orga!(orga)
          puts_process(type: 'setting parent orgas', processed: count += 1, all: childorgas.count)
        end

        count = 0
        events = Neos::Event.where(locale: :de).limit(limit[:events])
        puts "Step 3: Migrating #{events.count} events (#{Time.current.to_s})"
        events.each do |event|
          create_entry_and_handle_validation(event) do
            build_event_from_neos_event(event)
          end
          puts_process(type: 'events', processed: count += 1, all: events.count)
        end

        puts "Migration finished (#{Time.current.to_s})."
        puts "Categories: IS: #{::Category.count}, " +
          "SHOULD: #{SUB_CATEGORIES.keys.count} maincategories from configuration + " +
          "#{SUB_CATEGORIES.values.flatten.count} subcategories from configuration"
        puts "Orgas:: IS: #{::Orga.count}, SHOULD: #{orgas.count}"
        puts "Events: IS: #{::Event.count}, SHOULD: #{events.count}"
      end


      def migrate_event(entry_id)
        event = Neos::Event.where(entry_id: entry_id).first
        create_entry_and_handle_validation(event) do
          build_event_from_neos_event(event)
        end
      end

      def migrate_orga(entry_id)
        orga = Neos::Orga.where(entry_id: entry_id).first
        create_entry_and_handle_validation(orga) do
          build_orga_from_neos_orga(orga)
        end
        set_parent_orga_to_orga!(orga)
      end

      private

      def migrate_phraseapp_data(entry, new_entry)
        @client_old ||=
          PhraseAppClient.new(
            project_id: Settings.migration.phraseapp.project_id, token: Settings.migration.phraseapp.api_token)
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
            new_entry.attributes = translated_attributes.slice(*new_entry.class.translatable_attributes)
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
        if date_string.try(:strip).to_s =~ /\Ad{4}\z/
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

      def parent_or_root_orga(parent) # neos parent
        if parent && parent.orga? &&
            (orgas = ::Orga.where(legacy_entry_id: parent.entry_id)) &&
          (orgas.count == 1)
          orgas.first
        else
          ::Orga.root_orga
        end
      end

      def create_entry_and_handle_validation(entry)
        puts "migrating entry '#{entry.name}'"
        new_entry = yield

        new_entry.skip_phraseapp_translations! unless @migrate_phraseapp

        if new_entry.save
          # puts "saved valid entry '#{new_entry.title}'"
        else
          # binding.pry if new_entry.title.blank?
          new_entry.skip_short_description_validation = true
          if new_entry.save(validate: false)
            # puts "saved invalid entry '#{new_entry.title}'"
          else
            puts "Entry not creatable: #{new_entry.errors.messages}"
          end
          new_entry.skip_short_description_validation = false
        end

        # handle invalid entries
        if !new_entry.valid?
          # filter out any past events
          past_event =
            if new_entry.is_a?(::Event)
              new_entry.in?(::Event.past)
            else
              false
            end

          # add migration annotations only to future events and active entries
          if !past_event && new_entry.active
            # do not add annotations for short_descriptions
            details =
              new_entry.errors.full_messages.
                reject { |detail| detail == 'Kurzbeschreibung muss ausgefüllt werden' }

            create_annotations(new_entry, details)
          end
        end

        # convention (2017-05-31 with Jens):
        # We will migrate only the last updated location of an entry,
        # otherwise we do not know how to handle inheritance for locations
        # (Which location of the parent should be used for inheritance?)
        if entry.locations.any?
          create_location(new_entry, entry.locations.order('updated desc').first)
        end
        create_contact_info(new_entry, entry)

        if new_entry.persisted? && @migrate_phraseapp
          migrate_phraseapp_data(entry, new_entry)
        end

        new_entry
      rescue => exception
        puts '-------------------------------------------------------'
        puts "Entry could not be created for the following exception: #{exception.class}: #{exception.message}"
        puts 'Backtrace:'
        puts exception.backtrace[0..14].join("\n")
      end

      def create_location(new_entry, location)
        lat = location.lat.try(:strip)
        lon = location.lon.try(:strip)
        street = location.street.try(:strip)
        placename = location.placename.try(:strip)
        zip = location.zip.try(:strip)
        city = location.city.try(:strip)
        directions = location.arrival.try(:strip)

        unless lat.blank? && lon.blank? && street.blank? &&
            placename.blank? && zip.blank? && city.blank? && directions.blank?
          new_location =
            ::Location.new(locatable: new_entry, migrated_from_neos: true)

          set_attribute!(new_location, location.entry, :lat) do |entry|
            entry.locations.order('updated desc').first.try(:lat).try(:strip)
          end
          set_attribute!(new_location, location.entry, :lon) do |entry|
            entry.locations.order('updated desc').first.try(:lon).try(:strip)
          end
          set_attribute!(new_location, location.entry, :street) do |entry|
            entry.locations.order('updated desc').first.try(:street).try(:strip)
          end
          set_attribute!(new_location, location.entry, :placename) do |entry|
            entry.locations.order('updated desc').first.try(:placename).try(:strip)
          end
          set_attribute!(new_location, location.entry, :zip) do |entry|
            entry.locations.order('updated desc').first.try(:zip).try(:strip)
          end
          set_attribute!(new_location, location.entry, :city) do |entry|
            entry.locations.order('updated desc').first.try(:city).try(:strip)
          end
          set_attribute!(new_location, location.entry, :directions) do |entry|
            entry.locations.order('updated desc').first.try(:arrival).try(:strip)
          end

          unless new_location.save
            create_annotations(new_entry, new_location.errors.full_messages)
          end
        end
      end

      def create_contact_info(new_entry, entry)
        web = entry.web.try(:strip)
        social_media = entry.facebook.try(:strip)
        spoken_languages = entry.spokenlanguages.try(:strip)
        mail = entry.mail.try(:strip)
        phone = entry.phone.try(:strip)
        contact_person = entry.speakerpublic.try(:strip)

        if web.blank? && social_media.blank? && spoken_languages.blank? &&
            mail.blank? && phone.blank? && contact_person.blank?
          new_entry.add_inheritance_flag :contact_infos
          new_entry.save(validate: false)
        else
          new_contact_info =
            ContactInfo.new(contactable: new_entry, migrated_from_neos: true)

          set_attribute!(new_contact_info, entry, :web, by_recursion: true) do |entry|
            entry.web.try(:strip)
          end
          set_attribute!(new_contact_info, entry, :social_media, by_recursion: true) do |entry|
            entry.facebook.try(:strip)
          end
          set_attribute!(new_contact_info, entry, :spoken_languages, by_recursion: true) do |entry|
            entry.spokenlanguages.try(:strip)
          end
          set_attribute!(new_contact_info, entry, :mail, by_recursion: true) do |entry|
            entry.mail.try(:strip)
          end
          set_attribute!(new_contact_info, entry, :phone, by_recursion: true) do |entry|
            entry.phone.try(:strip)
          end
          set_attribute!(new_contact_info, entry, :contact_person, by_recursion: true) do |entry|
            entry.speakerpublic.try(:strip)
          end
          set_attribute!(new_contact_info, entry, :opening_hours, by_recursion: true) do |entry|
            entry.locations.first.try(:openinghours).try(:strip)
          end

          unless new_contact_info.save
            create_annotations(new_entry, new_contact_info.errors.full_messages)
          end
        end
      end

      def create_annotations(new_entry, details)
        [details].flatten.each do |detail|
          todo =
            Annotation.new(
              entry: new_entry,
              annotation_category: AnnotationCategory.where('title LIKE ?', 'Migration nur teilweise erfolgreich').first,
              detail: detail.try(:strip)
            )
          unless todo.save
            puts "Annotation is not valid, but we will save it. Errors: #{todo.errors.full_messages}"
            todo.save(validate: false)
          end
        end
      end

      def build_orga_from_neos_orga(orga)
        new_orga = ::Orga.new
        build_entry_from_neos_entry(orga, new_orga)
        new_orga
      end

      def set_parent_orga_to_orga!(orga)
        new_orga = ::Orga.where(legacy_entry_id: orga.entry_id).last
        if new_orga
          new_orga.parent = parent_or_root_orga(orga.parent)
          new_orga.save!(validate: false)
        end
      end

      def build_event_from_neos_event(event)
        new_event = ::Event.new
        build_entry_from_neos_entry(event, new_event)

        type_datetime_from =
          parse_datetime_and_return_type(:date_start, event.datefrom, event.timefrom)
        type_datetime_to =
          if event.timeto.blank?
            if event.dateto.blank?
              nil
            else
              if event.dateto == event.datefrom
                nil
              else
                parse_datetime_and_return_type(:date_end, event.dateto, event.timeto)
              end
            end
          else
            parse_datetime_and_return_type(:date_end,
              event.dateto.present? ? event.dateto : event.datefrom, event.timeto)
          end
        if type_datetime_from.first.nil? || type_datetime_from.last.nil?
          puts "failing on parsing date or time for event: #{event.inspect}"
        end

        if type_datetime_from
          new_event.date_start = type_datetime_from[0]
          new_event.time_start = type_datetime_from[1] == :datetime
        end
        if type_datetime_to
          new_event.date_end = type_datetime_to[0]
          new_event.time_end = type_datetime_to[1] == :datetime
        end
        new_event.parent_orga = parent_or_root_orga(event.parent)
        new_event.creator = User.first # TODO: assume that this is the system user → Is it?

        new_event
      end

      def build_entry_from_neos_entry(old_entry, new_entry)
        set_attribute!(new_entry, old_entry, :title, by_recursion: true) do |entry|
          entry.name.try(:strip)
        end

        set_attribute!(new_entry, old_entry, :description) do |entry|
          entry.description.try(:strip) || ''
        end

        set_attribute!(new_entry, old_entry, :short_description) do |entry|
          entry.descriptionshort.try(:strip) || ''
        end
        if new_entry.short_description.blank? && old_entry.parent.try(:descriptionshort).present?
          new_entry.add_inheritance_flag :short_description
        end

        set_attribute!(new_entry, old_entry, :media_url, by_recursion: true) do |entry|
          entry.image.try(:strip)
        end

        set_attribute!(new_entry, old_entry, :media_type, by_recursion: true) do |entry|
          entry.imagetype.try(:strip) # image | youtube
        end

        set_attribute!(new_entry, old_entry, :support_wanted, old_attribute: :supportwanted)
        set_attribute!(new_entry, old_entry, :for_children, old_attribute: :forchildren)
        set_attribute!(new_entry, old_entry, :certified_sfr, old_attribute: :certified)

        set_attribute!(new_entry, old_entry, :legacy_entry_id) do |entry|
          entry.entry_id.try(:strip)
        end

        new_entry.migrated_from_neos = true

        set_attribute!(new_entry, old_entry, :tags) do |entry|
          entry.try(:tags).try(:strip) || ''
        end

        new_entry.active = old_entry.published == true

        set_attribute!(new_entry, old_entry, :sub_category, by_recursion: true) do |entry|
          if entry.subcategory
            ::Category.find_by_title(entry.subcategory)
          end
        end

        set_attribute!(new_entry, old_entry, :category, by_recursion: true) do |entry|
          if entry.category
            ::Category.find_by_title(entry.category.name)
          end
        end
      end

      def set_attribute!(new_entry, old_entry, new_attribute, old_attribute: nil, by_recursion: false)
        tmp_entry = old_entry
        loop do
          value =
            if block_given?
              yield tmp_entry
            elsif old_attribute
              tmp_entry.send(old_attribute)
            else
              tmp_entry.send(new_attribute)
            end
          new_entry.send("#{new_attribute}=", value)
          tmp_entry = tmp_entry.parent

          break if new_entry.send(new_attribute).present? || tmp_entry.blank? || by_recursion == false
        end
        new_entry
      end
    end
  end
end
