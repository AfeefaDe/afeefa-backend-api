class Api::V1::BaseController < ApplicationController

  include DeviseTokenAuth::Concerns::SetUserByToken

  respond_to :json

  before_action :ensure_host
  before_action :ensure_protocol
  before_action :authenticate_api_v1_user!
  before_action :permit_params

  include JSONAPI::ActsAsResourceController

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    head :unprocessable_entity
  end

  on_server_error do |error|
    # do custom code or debugging here
    # binding.pry
    # pp error
    # pp error.backtrace
  end

  def context
    { current_user: current_api_v1_user }
  end

  private

  def ensure_host
    allowed_hosts = Settings.api.hosts
    if (host = request.host).in?(allowed_hosts)
      true
    else
      render(
          text: "wrong host: #{host}, allowed: #{allowed_hosts.join(', ')}",
          status: :unauthorized
      )
      false
    end
  end

  def ensure_protocol
    allowed_protocols = Settings.api.protocols
    if (protocol = request.protocol.gsub(/:.*/, '')).in?(allowed_protocols)
      true
    else
      render(
          text: "wrong protocol: #{protocol}, allowed: #{allowed_protocols.join(', ')}",
          status: :unauthorized
      )
      false
    end
  end

  def ensure_admin_secret
    if params[:admin_secret] == Settings.api.admin_secret
      true
    else
      head :forbidden
      false
    end
  end

  def permit_params
    params.try(:[], :data).try(:[], :attributes).try(:delete, :state)
    params.try(:[], :data).try(:[], :relationships).try(:delete, :creator)
  end
end
