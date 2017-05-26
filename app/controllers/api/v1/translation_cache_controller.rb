class Api::V1::TranslationCacheController < ApplicationController

  #before_action :ensure_token, only: :index

  def update
    translations = client.get_all_translations

    if translations.empty?
      render json: {msg: 'translation cache update failed'}, status: :unprocessable_entity

    else
      TranslationCache.delete_all

      translations.each do |t|
        if t.is_a?(PhraseApp::ResponseObjects::Translation)

          decoded_key = client.decode_key(t.key['name'])

          cached_entry = TranslationCache.find(
              cacheable_id: decoded_key['id'],
              cacheable_type: decoded_key['model'],
              language: t.locale['code']
          ) || TranslationCache.new(
              cacheable_id: decoded_key['id'],
              cacheable_type: decoded_key['model'],
              language: t.locale['code']
          )

          cached_entry["#{decoded_key['value']}"] = t.content

          cached_entry.save!
        end
      end

      render json: {msg: 'translation cache update succeeded'}, status: :ok
    end
  end

  def index
    timestamp = TranslationCache.minimum(:updated_at) || Time.at(0)

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