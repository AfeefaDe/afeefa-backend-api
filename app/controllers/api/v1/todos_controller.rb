class Api::V1::TodosController < Api::V1::BaseController
  def index
    present Todo::Operations::Index
    render json: @model
  end
end
