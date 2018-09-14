class FapiClient

  def job_created
    request({
      job_created: true
    })
  end

  def entry_translated(model, locale)
    request({
      type: model.class.translation_key_type,
      id: model.id,
      locale: locale
    })
  end

  def entry_updated(model)
    request({
      type: model.class.translation_key_type,
      id: model.id
    })
  end

  def entry_deleted(model)
    area = model.respond_to?(:area) ? model.area : nil
    request({
      area: area,
      type: model.class.translation_key_type,
      id: model.id,
      deleted: true
    })
  end

  def all_updated
    request({})
  end

  private

  def request(params)
    if Settings.afeefa.fapi_sync_active
      params[:token] = Settings.afeefa.fapi_webhook_api_token
      path = '/changes_webhook'
      path << "?#{params.to_query}" if params.keys.any?
      url = URI.parse(Settings.afeefa.fapi_url + path)
      request = Net::HTTP::Get.new(url.to_s)
      begin
        response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
          http.request(request)
        end
        response.body
      rescue StandardError
        Rails.logger.debug('fapi sync did not succeed. service not available')
      end
    end
  end

end
