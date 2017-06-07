require 'phrase_app_client'

class Api::V1::TranslationCacheController < ApplicationController

  def update
    @@client ||= ::PhraseAppClient.new
    translations = @@client.get_all_translations

    if translations[1].nil?
      if translations[0].empty?
        render json: { msg: 'no updates of translation cache necessary' }, status: :no_content
      else
        num = TranslationCache.rebuild_db_cache!(translations[0])
        render json: { msg: "translation cache update succeeded, #{num} translations cached" }
      end
    else
      render json: { error: translations[1] }, status: :unprocessable_entity
    end
  end

  def index
    timestamp = TranslationCache.minimum(:updated_at) || Time.at(0)

    render json: { updated_at: timestamp }
  end

  private

  def ensure_token
    if params.blank? || params[:token].blank? || params[:token] != Settings.translations.api_token
      head :unauthorized
    end
  end

end
