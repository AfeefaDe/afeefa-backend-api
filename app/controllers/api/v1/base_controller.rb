class Api::V1::BaseController < ApplicationController

  include DeviseTokenAuth::Concerns::SetUserByToken

  respond_to :json

  before_action :ensure_host
  before_action :ensure_protocol
  before_action :authenticate_api_v1_user!, except: %i(ping)
  before_action :ensure_admin_secret, only: %i(test_airbrake)

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "AccessDenied-Exception, message: #{exception.message}, from: #{exception.action}"
    head :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    head :unprocessable_entity
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

end
