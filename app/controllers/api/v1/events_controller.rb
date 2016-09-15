class Api::V1::EventsController < Api::V1::BaseController

  def show
    present Event::Operations::Show
    render json: @model
  end

  def index
    present Event::Operations::Index
    render json: @model
  end
end
