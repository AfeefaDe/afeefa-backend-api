require 'facebook_client'

class Api::V1::EventsController < Api::V1::BaseController

  skip_before_action :authenticate_api_v1_user!, only: :fbevents_neos
  before_action :ensure_token, only: :fbevents_neos

  def destroy
    super
  end

  def fbevents_neos
    render json: ::FacebookClient.new.get_events
  end
  alias_method :facebook_events_for_frontend, :fbevents_neos

  private

  def ensure_token
    if params.blank? || params[:token].blank? || params[:token] != Settings.facebook.api_token_for_event_request
      render :head, status: :unauthorized
      return
    end
  end

end
