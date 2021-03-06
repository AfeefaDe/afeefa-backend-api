require 'phraseapp-ruby'

class PhraseAppClient

  def initialize(project_id: nil, token: nil)
    @project_id = project_id || Settings.phraseapp.project_id
    @token = token || Settings.phraseapp.api_token || ''
    credentials = PhraseApp::Auth::Credentials.new(token: @token)
    @client = PhraseApp::Client.new(credentials)
  end

  def logger
    @logger ||=
      if log_file = Settings.phraseapp.log_file
        Logger.new(log_file)
      else
        Rails.logger
      end
  end

  def delete_translation(model)
    deleted = 0
    model.class.translatable_attributes.each do |attribute|
      key = model.build_translation_key(attribute)
      params = PhraseApp::RequestParams::KeysDeleteParams.new(q: key)
      affected = @client.keys_delete(@project_id, params).first.records_affected
      if affected.to_s == '0'
      else
        deleted = deleted + affected
      end
    end
    deleted
  end

  def get_all_translations(locales)
    translations = []

    locales.each do |locale|
      translationsForLocale = download_locale(locale)

      translationsForLocale.each do |type, translationForType|
        translationForType.each do |id, translationValues|
          translationValues.each do |key, value|
            translations.push({
              id: id,
              type: type,
              language: locale,
              key: key,
              content: value
            })
          end
        end
      end
    end

    translations
  end

  def upload_translation_file_for_locale(file, locale, tags: nil)
    begin
      params = PhraseApp::RequestParams::UploadParams.new(
        file: file.path,
        update_translations: true,
        tags: tags || '',
        encoding: 'UTF-8',
        file_format: 'nested_json',
        locale_id: locale
      )

      @client.upload_create(@project_id, params)
    rescue => exception
      message = 'Could not upload file '
      message << "for the following error: #{exception.message}\n"
      message << "#{exception.backtrace[0..14].join("\n")}"
      logger.error message
      raise message if Rails.env.development?
    end
  end

  def delete_all_keys
    begin
      params = PhraseApp::RequestParams::KeysDeleteParams.new(q: '*')
      @client.keys_delete(@project_id, params).first.records_affected
    rescue => exception
      if exception =~ 'unexpected status code (504) received'
        logger.warn 'PhraseAppServer timed out while deleting all keys.'
        -1
      else
        message = 'Could not delete all keys for '
        message << "the following error: #{exception.message}\n"
        message << "#{exception.backtrace[0..14].join("\n")}"
        logger.error message
        raise message if Rails.env.development?
      end
    end
  end

  def delete_keys_by_name(keys)
    keys = keys.dup
    count_deleted = 0
    while keys.any? do
      keys_to_process = keys.shift(300)
      q = 'name:' + keys_to_process.join(',')
      params = PhraseApp::RequestParams::KeysDeleteParams.new(q: q)
      count_deleted += @client.keys_delete(@project_id, params).first.records_affected
    end
    count_deleted
  end

  def delete_all_area_tags
    Translatable::AREAS.each do |area|
      delete_tag(area)
    end
  end

  def tag_all_areas
    num_tagged = 0
    Translatable::AREAS.each do |area|
      models_in_area =
        Orga.where(area: area) +
        Event.where(area: area) +
        DataModules::Offer::Offer.where(area: area) +
        DataModules::FeNavigation::FeNavigationItem.joins(:navigation).where(fe_navigations: {area: area})
      num_tagged += tag_models(area, models_in_area)
    end
    num_tagged
  end

  def delete_tag(tag)
    @client.tag_delete(@project_id, tag)
  rescue => exception
    if exception.message =~ /not found/
      Rails.logger.info "There is not tag to delete called #{tag}"
    else
      raise exception
    end
  end

  def get_count_keys_for_tag(tag)
    begin
      result = @client.tag_show(@project_id, tag)
      result.first.keys_count
    rescue => exception
      0
    end
  end

  def tag_models(tags, models)
    models = models.dup
    records_affected = 0

    while models.any? do
      models_to_process = models.shift(300)

      keys = []
      models_to_process.each do |model|
        keys << model.build_translation_key('title')
        if model.respond_to?('short_description') # orga, event
          keys << model.build_translation_key('short_description')
        elsif model.respond_to?('description') # offer
          keys << model.build_translation_key('description')
        end
      end
      q = 'name:' + keys.join(',')
      params = PhraseApp::RequestParams::KeysTagParams.new(tags: tags, q: q)
      records_affected += @client.keys_tag(@project_id, params).first.records_affected
    end

    records_affected
  end

  def sync_all_translations
    json = download_locale(Translatable::DEFAULT_LOCALE, true)
    # compare local keys and remove all remotes that do not exist or are empty locally
    delete_unused_keys(json)
    # compare local keys and update differing or create missing remote keys
    add_missing_or_invalid_keys(json)
    # simply remove all remote tags
    delete_all_area_tags
    # create area tags for all keys
    tag_all_areas
  end

  def delete_unused_keys(json)
    begin
      event_ids = json['event'].try(:keys) || []
      orga_ids = json['orga'].try(:keys) || []
      offer_ids = json['offer'].try(:keys) || []
      facet_item_ids = json['facet_item'].try(:keys) || []
      navigation_items_ids = json['navigation_item'].try(:keys) || []

      keys_to_destroy =
        get_keys_to_destroy(Orga, orga_ids) +
        get_keys_to_destroy(Event, event_ids) +
        get_keys_to_destroy(DataModules::Offer::Offer, offer_ids) +
        get_keys_to_destroy(DataPlugins::Facet::FacetItem, facet_item_ids) +
        get_keys_to_destroy(DataModules::FeNavigation::FeNavigationItem, navigation_items_ids)

      deleted = delete_keys_by_name(keys_to_destroy)

      Rails.logger.debug "deleted #{deleted} keys."
      return deleted
    rescue => exception
      Rails.logger.error 'error for delete_all_keys_not_used_in_database'
      Rails.logger.error exception.message
      Rails.logger.error exception.backtrace.join("\n")
      raise exception unless Rails.env.production?
    end
  end

  def add_missing_or_invalid_keys(json)
    updates_json = {}
    added = 0
    model_classes = [
      Orga,
      Event,
      DataModules::Offer::Offer,
      DataPlugins::Facet::FacetItem,
      DataModules::FeNavigation::FeNavigationItem
    ]
    model_classes.each do |model_class|
      model_class.all.each do |model|
        type = model.class.translation_key_type
        id = model.id.to_s
        if (
          # model not in json
          !json[type] ||
          !json[type][id] ||
          # title differs
          model.title.present? &&
            json[type][id]['title'] != model.title ||
          # short description differs
          model.respond_to?('short_description') &&
            model.short_description.present? &&
            json[type][id]['short_description'] != model.short_description
        )

          update_json = model.create_json_for_translation_file(only_changes: false)
          updates_json = updates_json.deep_merge(update_json)
          added += 1
        end
      end
    end

    file = write_translation_upload_json('missing-or-invalid-keys-', updates_json)
    upload_translation_file_for_locale(file, Translatable::DEFAULT_LOCALE)

    Rails.logger.info 'finished add_missing_keys'
    added
  end

  def write_translation_upload_json(filename, json)
    file = Tempfile.new([filename, '.json'], encoding: 'UTF-8')
    file.write(JSON.pretty_generate(json))
    file.close
    file
  end

  private

  def download_locale(locale, include_empty_translations = false)
    params = PhraseApp::RequestParams::LocaleDownloadParams.new(
      file_format: 'nested_json',
      encoding: 'UTF-8'
    )
    json = @client.locale_download(@project_id, locale, params).force_encoding('UTF-8')
    return JSON.parse json
  end

  def get_keys_to_destroy(model_class, ids)
    list = []
    ids.each do |id|
      if model = model_class.find_by(id: id)
        model_class.translatable_attributes.each do |attribute|
          if model.send(attribute).blank?
            list << model.build_translation_key(attribute)
          end
        end
      else
        list << model_class.build_translation_key(id, 'title')
        if model_class.translatable_attributes.include?(:short_description)
          list << model_class.build_translation_key(id, 'short_description')
        end
        if model_class.translatable_attributes.include?(:description)
          list << model_class.build_translation_key(id, 'description')
        end
      end
    end
    list
  end

end
