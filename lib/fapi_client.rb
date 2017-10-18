class FapiClient

  def entry_translated(model, locale)
    request({
      type: model.class.name.underscore,
      id: model.id,
      locale: locale
    })
  end

  def entry_updated(model)
    request({
      type: model.class.name.underscore,
      id: model.id
    })
  end

  def entry_deleted(model)
    request({
      area: model.area,
      type: model.class.name.underscore,
      id: model.id,
      deleted: true
    })
  end

  def all_updated
    request({})
  end

  private

  def request(params)
    params[:token] = Settings.afeefa.fapi_webhook_api_token
    path = '/changes_webhook'
    path << "?#{params.to_query}" if params.keys.any?
    url = URI.parse(Settings.afeefa.fapi_url + path)
    request = Net::HTTP::Get.new(url.to_s)
    response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
      http.request(request)
    end
    response.body
  end

end
