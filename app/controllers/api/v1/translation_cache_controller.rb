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

    entry = nil
    case type
    when 'orga'
      entry = Orga.find_by(id: id)
    when 'event'
      entry = Event.find_by(id: id)
    when 'facet_item'
      entry = DataPlugins::Facet::FacetItem.find_by(id: id)
    when 'navigation_item'
      entry = DataModules::FeNavigation::FeNavigationItem.find_by(id: id)
    end

    if entry
      if json['event'] == 'translations:create'
        TranslationCache.create!(
          cacheable_type: type,
          cacheable_id: id,
          title: field == 'title' ? content : nil,
          short_description: field == 'short_description' ? content : nil,
          language: language
        )
        render json: { status: 'ok' }, status: :created
      else
        TranslationCache.where(
          cacheable_type: type,
          cacheable_id: id,
          language: language
        ).update(field => content)
        render json: { status: 'ok' }, status: :ok
      end

      fapi_client.entry_translated(entry, language)
    end
  end

  def index
    timestamp = TranslationCache.minimum(:updated_at) || Time.at(0)

    render json: { updated_at: timestamp }
  end

  private

  def fapi_client
    @fapi_client ||= FapiClient.new
  end

  def token_to_ensure
    Settings.phraseapp.webhook_api_token
  end

end
