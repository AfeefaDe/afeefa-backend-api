module CustomHeaders

  extend ActiveSupport::Concern

  included do
    before_action :set_custom_headers

    private

    def set_custom_headers
      headers['Cache-Control']= 'private, max-age=0, no-cache'
    end
  end

end
