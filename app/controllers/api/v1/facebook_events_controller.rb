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
    origin = request.headers["Origin"]
    unless origin.nil?
      # change to nice [].each syntax
      if origin == "https://dev.afeefa.de"
        headers['Access-Control-Allow-Origin'] = origin
        headers['Access-Control-Request-Method'] = '*'
      elsif origin == "https://afeefa.de"
        headers['Access-Control-Allow-Origin'] = origin
        headers['Access-Control-Request-Method'] = '*'
      elsif origin == "http://localhost:3002"
        # maybe something like starts with localhost: would be better
        headers['Access-Control-Allow-Origin'] = origin
        headers['Access-Control-Request-Method'] = '*'
      end
    end
  end

end
