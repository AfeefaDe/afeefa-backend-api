class Api::V1::UsersController < Api::V1::BaseController

  def update
    user = current_api_v1_user
    attributes = params[:data][:attributes]
    allowed_attributes = attributes.permit(:forename, :surname, :organization, :password, :area)
    if user.update(allowed_attributes)
      render json: { data: user }
    else
      render status: 422, json: { errors: user.errors.to_hash  }
    end
  end

end
