class Api::V1::EventsController < Api::V1::BaseController

  require 'open-uri'

  def destroy
    super
  end

  def fbevents_neos
    events = []
    pages_events do |response|
      data = JSON.parse(response)
      data['data'].each do |event|
        events << event
      end
    end

    render json: events.uniq
  end

  private

  def pages_events
    File.readlines('config/fbpages.txt').each do |line|
      next if line[0] == '#'
      pageID = line.split(':')[1].strip
      response = open('https://graph.facebook.com/v2.8/'\
                    + pageID + \
                    '/events?'\
                    'access_token=EAACEdEose0cBAC3caPOvtDCDXr1XnbHUAzrRxgoX9CO92iyOOQGiUsZAaFZC35ZBc0qFZAwl2F134Jb0lzVR3uZBT6sD3qlz8uQhcq7x1Jn7qS3U7YEuXIND7jr6Q12NmBBxAXwy9sBxjZBzxAjXivNUogVEj6AAwFgfgm0FXoDHZASLhNlYTT1ZBZAOxMQSevTjeBGH8HEIZBWAZDZD'\
                    '&fields=name,place,description,start_time,end_time,category'
      ).read
      yield response
    end
  end
end
