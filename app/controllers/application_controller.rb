class ApplicationController < ActionController::API
  before_action :set_access_control_headers

  def set_access_control_headers
    if Rails.env.development?
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method']= '*'
    end
  end
end
