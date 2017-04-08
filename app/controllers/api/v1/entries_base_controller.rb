class Api::V1::EntriesBaseController < Api::V1::BaseController

  def index
    render json: { data: @objects.map(&:to_hash) || [] }
  end

  private

  def filter_whitelist
    [:title, :description].map(&:to_s).freeze
  end

  def custom_filter_whitelist
    [:todo].map(&:to_s).freeze
  end

  def apply_custom_filter!(attribute, objects)
    case attribute.to_s
      when 'todo'
        objects.annotated
      else
        objects
    end
  end

end
