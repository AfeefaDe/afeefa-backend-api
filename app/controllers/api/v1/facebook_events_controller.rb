require 'facebook_client'

class Api::V1::FacebookEventsController < ApplicationController

  before_action :ensure_token, only: :index
  before_action :set_access_control_headers

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

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = 'https://dev.afeefa.de'
    headers['Access-Control-Request-Method'] = '*'
  end

end
