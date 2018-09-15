class Api::V1::TranslationCacheController < Api::V1::BaseController

  include EnsureToken

  skip_before_action :authenticate_api_v1_user!, only: :phraseapp_webhook
  skip_before_action :ensure_token, except: :phraseapp_webhook

  def update
    PhraseappToBackendSyncJob.perform_later
    render json: { msg: 'translation cache update was triggered' }, status: :ok
  end

  def phraseapp_webhook
    json = JSON.parse(request.raw_post)
    type, id, field = json['translation']['key']['name'].split('.')
    content = json['translation']['content']
    language = json['translation']['locale']['code']

    entry = TranslationCache.phraseapp_entry_params_to_entry(type, id)

    if entry
      if json['event'] == 'translations:create'
        cache = TranslationCache.create!(
          cacheable_id: entry.id,
          cacheable_type: entry.class.name,
          title: field == 'title' ? content : nil,
          short_description: field == 'short_description' ? content : nil,
          description: field == 'description' ? content : nil,
          language: language
        )

        render json: { status: 'ok' }, status: :created
      else
        cache = TranslationCache.find_by(
          cacheable_id: entry.id,
          cacheable_type: entry.class.name,
          language: language
        )
        cache.update(field => content)
        render json: { status: 'ok' }, status: :ok
      end

      if cache.title.blank? && cache.short_description.blank? && cache.description.blank?
        cache.destroy
      end

      FapiCacheJob.new.update_entry_translation(entry, language)
    end
  end

  def index
    timestamp = TranslationCache.minimum(:updated_at) || Time.at(0)

    render json: { updated_at: timestamp }
  end

  private

  def token_to_ensure
    Settings.phraseapp.webhook_api_token
  end

end
