class Api::V1::EventsController < Api::V1::BaseController

  def show
    present Event::Operations::Show
    render json: @model
  end

  def index
    present Event::Operations::Index
    render json: @model
  end

  def create
    Event::Operations::Create.run(params) do
      head :created
      return
    end
    head :unprocessable_entity
  end
end
