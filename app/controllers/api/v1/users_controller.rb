class Api::V1::UsersController < Api::V1::BaseController

  def update
    user = current_api_v1_user
    attributes = params[:data][:attributes]
    attributes.permit(:forename, :surname, :organization, :password)
    user.update_attributes(attributes.permit(:forename, :surname, :organization, :password))
    render json: { data: user }
  end

end
