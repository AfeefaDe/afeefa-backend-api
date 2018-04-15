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

  def raw_get_upcoming_events(page:, page_id:)
    logger.debug "getting events for #{page}, page id #{page_id}"
    client.get_connections(
      page_id,
      # skip events in past, get owner
      'events?time_filter=upcoming&fields=id,name,description,place,start_time,end_time,owner')
  end

  def get_events(area:, sort_by_date_desc: false)
    processed_event_ids = []
    events = []

    pages = Settings.facebook.pages_for_events[area] || []
    pages.each do |page, page_id|
      events_for_page = raw_get_upcoming_events(page: page, page_id: page_id)
      events_for_page.each do |event|
        # skip already processed event ids
        id = event['id']
        if processed_event_ids.include?(id)
          next
        else
          processed_event_ids << id
        end
        event['link_to_event'] = "https://www.facebook.com/events/#{event['id']}"
        owner = event['owner']
        if owner.present?
          event['owner'] = owner['name']
          event['link_to_owner'] = "https://www.facebook.com/#{owner['id']}"
        end
        events << event
      end
    end
    events = events.flatten

    # sort events desc
    if sort_by_date_desc
      events.sort do |event1, event2|
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

    events
  end

end
