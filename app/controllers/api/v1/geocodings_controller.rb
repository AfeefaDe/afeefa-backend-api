class Api::V1::GeocodingsController < ApplicationController

  before_action :ensure_token, only: :index

  def index
    location = Location.new(geocoding_params)
    if coords = location.geocode
      render json: { latitude: coords.first, longitude: coords.last }
    else
      render json: 'geocoding failed', status: :unprocessable_entity
    end
  end
  alias_method :facebook_events_for_frontend, :index

  private

  def ensure_token
    if params.blank? || params[:token].blank? || params[:token] != Settings.geocoding.api_token
      head :unauthorized
      return
    end
  end

  def geocoding_params
    params.permit(:address, :street, :zip, :city, :country)
  end

end
