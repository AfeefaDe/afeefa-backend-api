class FacebookClient

  attr_reader :client

  def initialize
    @oauth = Koala::Facebook::OAuth.new(Settings.facebook.app_id, Settings.facebook.app_secret)
    @client = Koala::Facebook::API.new(@oauth.get_app_access_token)
  end

  def logger
    @logger ||=
      if log_file = Settings.facebook.log_file
        Logger.new(log_file)
      else
        Rails.logger
      end
  end

  def import_events
    orgas = Orga.where.not(facebook_id: nil).all

    orgas.each do |orga|
      logger.debug "getting events for #{orga.title}, page id #{orga.facebook_id}"
      events_for_page = client.get_connections(orga.facebook_id, 'events?time_filter=upcoming&fields=id,name,description,place,start_time,end_time,owner')
      events_for_page.each do |event|
        pp event
        # owner = Orga.where(facebook_id: event['owner']['id']).first
      end
    end

    return 'test'
  end

  def get_events
    processed_event_ids = []
    events = []

    Settings.facebook.pages_for_events.each do |page, page_id|
      logger.debug "getting events for #{page}, page id #{page_id}"
      events_for_page = client.get_connections(page_id, 'events')
      events_for_page.each do |event|
        # skip already processed event ids
        id = event['id']
        if processed_event_ids.include?(id)
          next
        else
          processed_event_ids << id
        end
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
    events.flatten.sort do |event1, event2|
      event1_end = Time.zone.parse(event1['end_time']).to_i rescue nil
      event2_end = Time.zone.parse(event2['end_time']).to_i rescue nil
      event1_start = Time.zone.parse(event1['start_time']).to_i rescue nil
      event2_start = Time.zone.parse(event2['start_time']).to_i rescue nil
      if event1_end.present? || event2_end.present?
        event1_end <=> event2_end || -1
      else
        event1_start <=> event2_start || -1
      end
    end
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
