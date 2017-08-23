module EnsureToken

  extend ActiveSupport::Concern

  included do
    before_action :ensure_token

    private

    def ensure_token
      if params.blank? || params[:token].blank? || params[:token] != token_to_ensure
        head :unauthorized
        return
      end
    end

    def token_to_ensure
      raise 'Override method token_to_ensure in using class!'
    end
  end

end
