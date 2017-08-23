class Api::V1::GeocodingsController < ApplicationController

  include EnsureToken
  include Cors

  def index
    location = Location.new(geocoding_params)
    results = Geocoder.search(location.address_for_geocoding)
    if results && results.any? && result = results.first
      street = result.address.split(',').first
      render json: {
        latitude: result.latitude,
        longitude: result.longitude,
        street: street,
        city: result.city,
        full_address: result.address
      }
    else
      render json: 'geocoding failed', status: :unprocessable_entity
    end
  end

  private

  def geocoding_params
    params.permit(:address, :street, :zip, :city, :country)
  end

  # for EnsureToken
  def token_to_ensure
    Settings.geocoding.api_token
  end

end
