require 'facebook_client'

class Api::V1::FacebookEventsController < ApplicationController

  before_action :ensure_token, only: :index

  def index
    render json: ::FacebookClient.new.get_events
  end
  alias_method :facebook_events_for_frontend, :index

  private

  def ensure_token
    if params.blank? || params[:token].blank? || params[:token] != Settings.facebook.api_token_for_event_request
      head :unauthorized
      return
    end
  end

end
