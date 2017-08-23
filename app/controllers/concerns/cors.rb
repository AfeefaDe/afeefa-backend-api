module Cors

  extend ActiveSupport::Concern

  included do
    before_action :set_cors_headers

    private

    def set_cors_headers
      default_allowed_origins =
        %w(
            http://localhost:3000
            http://localhost:3002
            https://dev.afeefa.de
            https://afeefa.de
        )
      allowed_origins = (Settings.api.allowed_cors_origins rescue nil) || default_allowed_origins

      given_origin = request.headers['Origin']

      if given_origin.in?(default_allowed_origins)
        headers['Access-Control-Allow-Origin'] = given_origin
        headers['Access-Control-Request-Method'] = '*'
      end
    end
  end

end
