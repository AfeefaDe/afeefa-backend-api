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
          { name: 'german-course-state', id: '1-2' },
          { name: 'meet-and-speak', id: '1-3' },
          { name: 'learning-place', id: '1-4' },
          { name: 'interpreter', id: '1-5' },
          { name: 'foreign-language', id: '1-6' }
        ],
        medic: [
          { name: 'medical-counselling', id: '2-2' },
          { name: 'psychological-counselling', id: '2-3' }
        ],
        jobs: [
          { name: 'job-counselling', id: '3-1' },
          { name: 'education-counselling', id: '3-2' },
          { name: 'political-education', id: '3-3' },
          { name: 'library', id: '3-4' }
        ],
        consultation: [
          { name: 'asylum-counselling', id: '4-1' },
          { name: 'legal-advice', id: '4-2' },
          { name: 'social-counselling', id: '4-3' },
          { name: 'family-counselling', id: '4-4' },
          { name: 'volunteer-coordination', id: '4-5' }
        ],
        leisure: [
          { name: 'sports', id: '5-2' },
          { name: 'museum', id: '5-3' },
          { name: 'music', id: '5-4' },
          { name: 'stage', id: '5-5' },
          { name: 'craft-art', id: '5-6' },
          { name: 'workspace', id: '5-7' },
          { name: 'gardening', id: '5-8' },
          { name: 'cooking', id: '5-9' },
          { name: 'festival', id: '5-10' },
          { name: 'lecture', id: '5-11' },
          { name: 'film', id: '5-12' },
          { name: 'congress', id: '5-13' }
        ],
        community: [
          { name: 'welcome-network', id: '6-1' },
          { name: 'meeting-place', id: '6-2' },
          { name: 'youth-club', id: '6-3' },
          { name: 'childcare', id: '6-4' },
          { name: 'workshop', id: '6-5' },
          { name: 'sponsorship', id: '6-6' },
          { name: 'lgbt', id: '6-7' },
          { name: 'housing-project', id: '6-8' }
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
        reset_progress
        categories.each do |category|
          next if ::Category.find_by_title(category.name)
          new_category = ::Category.new(title: category.name.try(:strip))
          unless new_category.save
            puts "Category is not valid, but we will save it. Errors: #{new_category.errors.full_messages}"
            new_category.save(validate: false)
          end
          puts_progress(type: 'categories', processed: count += 1, all: categories.count)
        end

        count = 0
        orgas = Neos::Orga.where(locale: :de).limit(limit[:orgas])
        puts "Step 2: Migrating #{orgas.count} orgas (#{Time.current.to_s})"
        reset_progress
        orgas.each do |orga|
          create_entry_and_handle_validation(orga) do
            build_orga_from_neos_orga(orga)
          end
          puts_progress(type: 'orgas', processed: count += 1, all: orgas.count)
        end

        count = 0
        # FIXME: Limit can be wrong here, assume there is a limit of 100 and
        # there are 100 orgas without parent and 100 with parent → Too much childorgas would be processed...
        childorgas = Neos::Orga.where(locale: :de).where.not(parent_entry_id: nil).limit(limit[:orgas])
        puts "Step 2b: Setting parent to #{childorgas.count} child orgas (#{Time.current.to_s})"
        reset_progress
        childorgas.each do |orga|
          set_parent_orga_to_orga!(orga)
          puts_progress(type: 'setting parent orgas', processed: count += 1, all: childorgas.count)
        end

        count = 0
        orgas = Neos::Orga.where(locale: :de).limit(limit[:orgas])
        puts "Step 2c: Setting #{orgas.count} orga timestamps and handle inheritance stuff (#{Time.current.to_s})"
        reset_progress
        orgas.each do |orga|
          new_orga = ::Orga.find_by(legacy_entry_id: orga.entry_id)
          # skip phraseapp stuff here
          new_orga.skip_phraseapp_translations!
          set_timestamps(new_orga, orga)
          # association to parent set in 2b, so we can do this here
          handle_inheritance(new_orga)
          puts_progress(type: 'setting orga timestamps', processed: count += 1, all: orgas.count)
        end

        count = 0
        events = Neos::Event.where(locale: :de).limit(limit[:events])
        puts "Step 3: Migrating #{events.count} events (#{Time.current.to_s})"
        reset_progress
        events.each do |event|
          create_entry_and_handle_validation(event) do
            build_event_from_neos_event(event)
          end
          puts_progress(type: 'events', processed: count += 1, all: events.count)
        end

        count = 0
        events = Neos::Event.where(locale: :de).limit(limit[:events])
        puts "Step 3b: Setting #{events.count} event timestamps and handle inheritance stuff (#{Time.current.to_s})"
        reset_progress
        events.each do |event|
          new_event = ::Event.find_by(legacy_entry_id: event.entry_id)
          # skip phraseapp stuff here
          new_event.skip_phraseapp_translations!
          set_timestamps(new_event, event)
          puts_progress(type: 'setting event timestamps', processed: count += 1, all: events.count)
        end

        puts "Step 4: Migrating PhraseApp (#{Time.current.to_s})"
        reset_progress
        if @migrate_phraseapp
          migrate_phraseapp_faster(show_objects_in_phraseapp_not_found_in_database_errors: false)
        else
          puts '(skipped)'
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
        new_event = create_entry_and_handle_validation(event) do
          build_event_from_neos_event(event)
        end
        set_timestamps(new_event, event)
      end

      def migrate_orga(entry_id)
        orga = Neos::Orga.where(entry_id: entry_id).first
        new_orga = create_entry_and_handle_validation(orga) do
          build_orga_from_neos_orga(orga)
        end
        set_parent_orga_to_orga!(orga)
        set_timestamps(new_orga, orga)
      end

      def migrate_phraseapp_faster#(show_objects_in_phraseapp_not_found_in_database_errors: true)
        ActiveRecord::Base.logger.level = 1

        @client_old ||=
          PhraseAppClient.new(
            project_id: Settings.migration.phraseapp.project_id,
            token: Settings.migration.phraseapp.api_token)
        @client_new ||= PhraseAppClient.new

        puts 'Cleaning up phraseapp.'
        delete_count = @client_new.delete_all_keys
        puts "Cleaned up phraseapp. Deleted #{delete_count} keys."

        translation_hash = {}

        @client_old.locales.each_with_index do |locale, index|
          translation_hash[locale] = {
            event: {},
            orga: {}
          }

          file = @client_old.get_locale_file(locale)

          File.open(file, 'rb:UTF-8').read.scan(/"([0-9]+[0-z]*)": ({[^}]*?})/) do |legacy_id, content|
            object = ::Orga.find_by(legacy_entry_id: legacy_id)
            if object.nil?
              object = ::Event.find_by(legacy_entry_id: legacy_id)
              old_entry = Entry.find_by(entry_id: legacy_id)

              if old_entry.nil?
                # this seems to be an old phraseapp key, entry does no longer exist, skip it
                next
              end

              unless old_entry.orga? || old_entry.event?
                # this is POI or marketentry, these should not be migrated yet
                next
              end

              if object.nil?
                if show_objects_in_phraseapp_not_found_in_database_errors
                  puts "no orga or event with legacy_id #{legacy_id} found, old entry was: #{old_entry.inspect}"
                end
                next
              end
              type = :event
            else
              type = :orga
            end

            old_translation = JSON.parse(content)
            new_translation = old_translation.deep_dup
            new_translation['title'] = new_translation.delete('name')
            new_translation['short_description'] = new_translation.delete('descriptionshort')

            translation_hash[locale][type][object.id] = new_translation
          end

          phraseapp_translations_dir = Rails.root.join('tmp', 'translations')
          FileUtils.mkdir_p(phraseapp_translations_dir)
          phraseapp_translations_file_path =
            File.join(phraseapp_translations_dir, "translation-new-#{locale}.json")
          file = File.new(phraseapp_translations_file_path, 'w:UTF-8')
          file.write(JSON.pretty_generate(translation_hash[locale]))
          file.close

          @client_new.push_locale_file(file.path, @client_new.locale_id(locale))

          puts_progress(type: 'migrating phraseapp', processed: index + 1, all: @client_old.locales.count)
        end
      end

      private

      def migrate_phraseapp_data(entry, new_entry)
        @client_old ||=
          PhraseAppClient.new(
            project_id: Settings.migration.phraseapp.project_id,
            token: Settings.migration.phraseapp.api_token)
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

      def puts_progress(type:, processed:, all:)
        @old_percent ||= 0
        percent = processed.to_f / all * 100
        if percent - @old_percent > 10
          @old_percent = percent
          puts "processed #{processed} of #{all} #{type}: #{'%.2f' % (percent)}%"
        end
      end

      def reset_progress
        @old_percent = 0
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
        # puts "migrating entry '#{entry.name}'"
        new_entry = yield

        # we are bulk migrating the phraseapp translations in step 4
        new_entry.skip_phraseapp_translations!

        # association to parent is created later, so can not check inheritance stuff here
        new_entry.skip_unset_inheritance = true

        if new_entry.save
          # puts "saved valid entry '#{new_entry.title}'"
        else
          # binding.pry if new_entry.title.blank?
          new_entry.skip_validations_for_migration = true
          if new_entry.save(validate: false)
            # puts "saved invalid entry '#{new_entry.title}'"
          else
            puts "Entry not creatable: #{new_entry.errors.messages}"
          end
          new_entry.skip_validations_for_migration = false
        end

        # handle invalid entries
        if !new_entry.valid?
          # filter out any past events
          past_event =
            if new_entry.is_a?(::Event)
              new_entry.in?(::Event.past) &&
                # events without date_start should be validated
                # because we do not really know if they are gone
                new_entry.date_start.present?
            else
              false
            end

          # add migration annotations only to not past events and active entries
          if !past_event &&
              # epic fuck up on active getter in state machine -> TODO/FIXME: Fix this!
              new_entry.instance_variable_get('@active')
            create_annotations(new_entry, new_entry.errors.full_messages)
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

        # we are bulk migrating the phraseapp translations in step 4
        # if new_entry.persisted? && @migrate_phraseapp
        #   migrate_phraseapp_data(entry, new_entry)
        # end

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

          if entry.parent.present?
            new_entry.add_inheritance_flag :contact_infos
          end

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
          annotation_category =
            AnnotationCategory.where('title LIKE ?', detail).first ||
              AnnotationCategory.where('title LIKE ?', 'Migration nur teilweise erfolgreich').first
          todo =
            Annotation.new(
              entry: new_entry,
              annotation_category: annotation_category,
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

      def set_timestamps(new_entry, entry)
        ActiveRecord::Base.record_timestamps = false
        new_entry.created_at = entry.created
        new_entry.updated_at = entry.updated
        new_entry.save(validate: false)
        ActiveRecord::Base.record_timestamps = true
      end

      def handle_inheritance(new_entry)
        new_entry.skip_unset_inheritance = false
        # run before_validation hook for handling inheritance
        new_entry.valid?
        new_entry.save(validate: false)
      end

      def set_parent_orga_to_orga!(orga)
        new_orga = ::Orga.where(legacy_entry_id: orga.entry_id).last
        if new_orga
          # skip phraseapp stuff here
          new_orga.skip_phraseapp_translations!
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
        new_event.orga = parent_or_root_orga(event.parent)
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

        set_attribute!(new_entry, old_entry, :area)
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
