class Api::V1::EntriesBaseController < Api::V1::BaseController

  def index
    json_hash =
      @objects.try do |objects|
        objects.map do |object|
          object.try(:to_hash, with_relationships: true)
        end
      end || []
    render json: { data: json_hash }
  end

  def show
    render json: { data: @objects.find(params[:id]).try(:to_hash, details: true, with_relationships: true) }
  end

  private

  def filter_whitelist
    [:title, :description].map(&:to_s).freeze
  end

  def custom_filter_whitelist
    [:todo].map(&:to_s).freeze
  end

end
