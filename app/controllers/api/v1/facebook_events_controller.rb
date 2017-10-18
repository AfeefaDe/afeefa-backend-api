class Api::V1::FacebookEventsController < ApplicationController

  include EnsureToken
  include Cors

  def index
    render json: ::FacebookClient.new.get_events
  end
  alias_method :facebook_events_for_frontend, :index

  private

  # for EnsureToken
  def token_to_ensure
    Settings.facebook.api_token_for_event_request
  end

end
