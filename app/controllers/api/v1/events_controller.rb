class Api::V1::EventsController < Api::V1::BaseController

  require 'open-uri'

  def destroy
    super
  end

  def fbevents_neos
    render json: pages_events
  end
  alias_method :facebook_events_for_frontend, :fbevents_neos

  private

  def pages_events
    events = []
    Settings.facebook.pages_for_events.each do |page, page_id|
      Rails.logger.debug "getting events for #{page}, page id #{page_id}"
      events_for_page =
        open("https://graph.facebook.com/v2.8/#{page_id.to_s}/events?access_token=#{Settings.facebook.access_token}" +
          '&fields=name,place,description,start_time,end_time,category'
        ).read
      events << JSON.parse(events_for_page)['data']
    end
    events.flatten.uniq
  end

end
