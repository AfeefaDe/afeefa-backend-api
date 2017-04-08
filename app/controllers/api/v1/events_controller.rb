class Api::V1::EventsController < Api::V1::BaseController

  def index
    render json: { data: @objects.map(&:to_json) || [] }
  end

  private

  def filter_whitelist
    [:title, :description].map(&:to_s).freeze
  end

end
