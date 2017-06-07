require 'phrase_app_client'

class Api::V1::TranslationCacheController < Api::V1::BaseController

  def update
    translations = client.get_all_translations

    if translations[1].nil?
      if translations[0].empty?
        render json: {msg: 'no updates of translation cache necessary'}, status: :no_content
      else
        TranslationCache.delete_all

        num = 0
        translations[0].each do |t|
          if t.is_a?(PhraseApp::ResponseObjects::Translation) && t.locale['code'] != Translatable::DEFAULT_LOCALE

            decoded_key = client.decode_key(t.key['name'])

            cached_entry = TranslationCache.find_by(
                cacheable_id: decoded_key[:id],
                cacheable_type: decoded_key[:model],
                language: t.locale['code']
            ) || TranslationCache.new(
                cacheable_id: decoded_key[:id],
                cacheable_type: decoded_key[:model],
                language: t.locale['code']
            )

            cached_entry.send("#{decoded_key[:attribute]}=", t.content)

            cached_entry.save!

            num += 1
          end
        end

        render json: {msg: "translation cache update succeeded, #{num} translations cached"}, status: :ok
      end
    else
      render json: {error: translations[1]}, status: :unprocessable_entity

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
    @@client ||= ::PhraseAppClient.new
  end

  def ensure_token
    if params.blank? || params[:token].blank? || params[:token] != Settings.translations.api_token
      head :unauthorized
    end
  end
end