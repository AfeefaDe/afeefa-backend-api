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
    path = "/changes_webhook?#{params.to_query}"
    url = URI.parse(Settings.afeefa.fapi_url + path)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    res.body
  end

end