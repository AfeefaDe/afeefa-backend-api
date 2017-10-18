class Api::V1::SessionsController < DeviseTokenAuth::SessionsController

  include NoCaching

  before_action :configure_permitted_parameters

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:format])
  end

end
