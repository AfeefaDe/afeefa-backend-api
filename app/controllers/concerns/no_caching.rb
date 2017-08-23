module NoCaching

  extend ActiveSupport::Concern

  included do
    before_action :set_no_cache_header

    private

    def set_no_cache_header
      headers['Cache-Control']= 'private, max-age=0, no-cache'
    end
  end

end
