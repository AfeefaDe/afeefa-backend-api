class Api::V1::UsersController < Api::V1::BaseController

  def show
    render json: User.find(params[:id])
  end

  def list_orgas
    present User::ListOrgas
    render json: @model
  end

  def list_events
    present User::ListEvents
    render json: @model
  end

  private
  def params!(params)
    params.merge(current_user: current_api_v1_user)
  end

end
