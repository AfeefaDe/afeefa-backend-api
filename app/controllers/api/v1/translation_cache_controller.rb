require 'phrase_app_client' #TODO: could vanish any time, may be

class Api::V1::TranslationCacheController < Api::V1::BaseController
  include EnsureToken

  skip_before_action :authenticate_api_v1_user!, only: :phraseapp_hook
  skip_before_action :ensure_token, except: :phraseapp_webhook

  def update
    TranslationCacheJob.perform_later
    render json: {msg: 'translation cache update was triggered'}, status: :ok
  end

  def phraseapp_webhook
    render json: {status: 'ok'}
  end

  def index
    timestamp = TranslationCache.minimum(:updated_at) || Time.at(0)

    render json: {updated_at: timestamp}
  end

  private

  def token_to_ensure
    Settings.phraseapp.webhook_api_token
  end

end
