require 'facebook_client'

class Api::V1::EventsController < Api::V1::BaseController

  def destroy
    super
  end

  def fbevents_neos
    render json: ::FacebookClient.new.get_events
  end
  alias_method :facebook_events_for_frontend, :fbevents_neos

end
