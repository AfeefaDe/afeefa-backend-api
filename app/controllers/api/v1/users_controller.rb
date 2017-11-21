class Api::V1::UsersController < Api::V1::BaseController

  def update
    user = User.find(params[:id])
    attributes = params[:data][:attributes]
    user.update_attributes(attributes.permit(:forename, :surname, :organization))
    render json: { data: user }
  end

end
