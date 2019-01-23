class Api::V1::ApiBasicsController < ApplicationController
  respond_to :json

  before_action :authenticate_api_v1_user!
  around_action :set_current_user

  # https://stackoverflow.com/questions/27673352/how-access-to-helper-current-user-in-model-rails/43271062#43271062
  # necessary to allow facet items to be filtered depending on the current user's area
  def set_current_user
    Current.user = current_api_v1_user
    yield
  ensure
    Current.user = nil
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    head :unprocessable_entity
  end
end
