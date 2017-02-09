class FacebookClient

  attr_reader :client

  def initialize
    @oauth = Koala::Facebook::OAuth.new(Settings.facebook.app_id, Settings.facebook.app_secret)
    @client = Koala::Facebook::API.new(@oauth.get_app_access_token)
  end

  def get_events
    events = []
    Settings.facebook.pages_for_events.each do |page, page_id|
      Rails.logger.debug "getting events for #{page}, page id #{page_id}"
      events_for_page = client.get_connections(page_id, 'events')
      events_for_page.each do |event|
        # skip events in past
        end_time = event['end_time']
        start_time = event['start_time']
        if (end_time.present? && Time.zone.parse(end_time) < Time.current) ||
            (end_time.blank? && start_time.present? && Time.zone.parse(start_time) < Time.current)
          next
        end
        event['link_to_event'] = "https://www.facebook.com/events/#{event['id']}"
        event['owner'] = page
        event['link_to_owner'] = "https://www.facebook.com/#{page_id}"
        # if event['photos'].any?
        #   event['link_to_photo'] = get_photo_url_for_photo_id(event['photos']['data'].first['id'])
        # end
        events << event
      end
    end

    # sort events desc
    events.flatten.uniq.sort do |event1, event2|
      event1_end = Time.zone.parse(event1['end_time']).to_i rescue nil
      event2_end = Time.zone.parse(event2['end_time']).to_i rescue nil
      event1_start = Time.zone.parse(event1['start_time']).to_i rescue nil
      event2_start = Time.zone.parse(event2['start_time']).to_i rescue nil
      if event1_end.present? || event2_end.present?
        event1_end <=> event2_end
      else
        event1_start <=> event2_start
      end
    end.reverse
  end

  # def get_photo_url_for_photo_id(photo_id)
  #   html = open("https://facebook.com/#{photo_id}").read
  #   doc = Nokogiri::HTML(html)
  #   img = doc.css('img').first
  #   binding.pry
  #   pp img.inspect
  #   pp img.attributes
  # end

end
