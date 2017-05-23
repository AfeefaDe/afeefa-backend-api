class Api::V1::TranslationCacheController < ApplicationController

  before_action :ensure_token, only: :index

  def update
    translations = client.get_all_translations

    translations.each do |t|
      # todo handle translations
    end

    if true
      render json: 'translation cache update succeeded', status: :ok
    else
      render json: 'translation cache update failed', status: :unprocessable_entity
    end
  end

  def index
    timestamp = TranslationCache.minimum(:updated_at)

    render json: {
        updated_at: timestamp
    }
  end


  private

  def client
    @@client ||= PhraseAppClient.new
  end

  def ensure_token
    if params.blank? || params[:token].blank? || params[:token] != Settings.translations.api_token
      head :unauthorized
    end
  end
end