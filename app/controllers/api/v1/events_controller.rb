class Api::V1::EventsController < Api::V1::BaseController

  def show
    present Event::Show
    render json: @model
  end

  def index
    present Event::Index
    render json: @model
  end
end
