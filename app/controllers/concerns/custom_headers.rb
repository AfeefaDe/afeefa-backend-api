module CustomHeaders

  extend ActiveSupport::Concern

  included do
    before_action :set_custom_headers

    protected

    def update_auth_header
      super
      pp "#{request.url}\ndelivered the following access-token in header:\n#{response.headers['access-token']}"
    end

    private

    def set_custom_headers
      # actually we do not want a CORS header:
      # allowed_hosts = Settings.api.hosts
      # allowed_protocols = Settings.api.protocols
      # access_control_allow_origin = []
      #
      # allowed_protocols.each do |protocol|
      #   allowed_hosts.each do |host|
      #     access_control_allow_origin <<
      #       if protocol == '*' || host == '*'
      #         '*'
      #       else
      #         "#{protocol}://#{host}"
      #       end
      #   end
      # end
      #
      # headers['Access-Control-Allow-Origin'] = access_control_allow_origin.join(' | ')
      # headers['Access-Control-Request-Method']= '*'

      # no caching please:
      headers['Cache-Control']= 'private, max-age=0, no-cache'
    end

  end

end
