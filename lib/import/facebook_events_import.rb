module Import
  module FacebookEventsImport

    class << self
      def import(limit: nil)
        limit = limit.to_i if limit
        processed = 0
        imported = 0
        warnings = []
        errors = []
        client_fb = FacebookClient.new

        Translatable::AREAS.each do |area|
          pages = Settings.facebook.pages_for_events[area] || []
          pages.each do |page, page_id|
            events_for_page = client_fb.raw_get_upcoming_events(page: page, page_id: page_id)
            events_for_page.each do |event_fb|
              begin
                if limit && processed >= limit
                  pp "limit of objects to process reached (#{limit})"
                  break
                  break
                end

                processed = processed + 1

                next unless element_in_area?(element: event_fb, area: area)
                event_fb_id = event_fb['id']
                events = Event.where(facebook_id: event_fb_id).presence || [Event.new]
                events.each do |event|
                  event.facebook_id = event_fb_id
                  event.title = event_fb['name'].chars.select(&:valid_encoding?).join

                  event.date_start = parse_datetime(event_fb['start_time'])
                  event.date_end = parse_datetime(event_fb['end_time'])

                  event.short_description = ensure_valid_encoding(event_fb['description'])
                  event.skip_short_description_validation!

                  place_fb = event_fb['place']
                  location_fb = place_fb && place_fb['location']
                  location = nil
                  if location_fb.present?
                    location = event.locations.first || Location.new(locatable: event)
                    location.placename = place_fb['name']
                    location.lat = location_fb['latitude']
                    location.lon = location_fb['longitude']
                    location.street = location_fb['street']
                    location.zip = location_fb['zip']
                    location.city = location_fb['city']
                    # location.country = location_fb['country']
                  end

                  event.area = area

                  orga_fb_id = event_fb['owner']['id']
                  orga = Orga.where(facebook_id: orga_fb_id).first
                  event.orga = orga

                  # skip this event if its owner does not belong to the area
                  if orga.area != area
                    warnings << "Facebook-ID: #{event_fb_id} – Skip event because its owner does not belong to area #{area}"
                    next
                  end

                  if orga && category = orga.category
                    event.category = category
                  else
                    warnings << "Facebook-ID: #{event_fb_id} – Could not find category for orga with facebook id '#{orga_fb_id}'!"
                    event.category = Category.by_area(area).where(title: 'fb-event').last
                  end

                  event.save!
                  if location
                    location.locatable = event
                    location.save!
                  end

                  if event.orga_id.blank?
                    warnings << "ID: #{event.id} – Facebook-ID: #{event_fb_id} – Could not find orga with facebook id '#{orga_fb_id}'!"
                  end

                  imported = imported + 1
                end
              rescue => exception
                message = "Error while importing, during facebook event with id #{event_fb_id}:\n\n"
                message << "#{exception.message}\n"
                errors << message
              end
            end
          end
        end

        print_summary(list: warnings, type: 'warnings')
        print_summary(list: errors)
        pp "imported: #{imported}\n"

        imported
      end

      def element_in_area?(element:, area:)
        place_fb = element['place']
        location_fb = place_fb && place_fb['location']
        lat = location_fb['latitude']
        lat = lat && lat.to_f
        lon = location_fb['longitude']
        lon = lon && lon.to_f
        area = Area[area]
        lat_min = area.lat_min.to_f
        lat_max = area.lat_max.to_f
        lon_min = area.lon_min.to_f
        lon_max = area.lon_max.to_f

        lat_min <= lat && lat <= lat_max &&
          lon_min <= lon && lon <= lon_max
      end

      def parse_datetime(datetime)
        Time.zone.parse(
          DateTime.parse(
            datetime.to_s).to_s)
      end

      # to get rid of invalid encoding on facebook import:
      def ensure_valid_encoding(string)
        sanitized = string.each_char.select { |c| c.bytes.count < 4 }.join
        if sanitized.length < string.length
          if removed = string.each_char.select { |c| c.bytes.count >= 4 }.join
            Rails.logger.debug("removed invalid encoded elements: #{removed}")
          end
        end
        sanitized
      end

      def print_summary(list:, type: 'errors')
        list.each do |element|
          pp element
        end
        pp "overall #{type}: #{list.count}\n"
      end

    end
  end
end
