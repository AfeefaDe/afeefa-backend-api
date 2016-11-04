module CrossOriginHeader

  extend ActiveSupport::Concern

  included do
    before_action :set_access_control_headers

    private

    def set_access_control_headers
      allowed_hosts = Settings.api.hosts
      allowed_protocols = Settings.api.protocols
      access_control_allow_origin = []

      allowed_protocols.each do |protocol|
        allowed_hosts.each do |host|
          access_control_allow_origin <<
            if protocol == '*' || host == '*'
              '*'
            else
              "#{protocol}://#{host}"
            end
        end
      end

      headers['Access-Control-Allow-Origin'] = access_control_allow_origin.join(' | ')
      headers['Access-Control-Request-Method']= '*'
    end

  end

end
