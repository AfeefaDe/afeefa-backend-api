require 'http'

class Api::V1::ChaptersController < Api::V1::BaseController

  include DeviseTokenAuth::Concerns::SetUserByToken
  include NoCaching
  include ChaptersApi

  skip_before_action :authenticate_api_v1_user!, only: :show

  respond_to :json

  # before_action :authenticate_api_v1_user!

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    head :unprocessable_entity
  end

  def initialize
    super
  end

  def index
    response = HTTP.get(base_path)
    render status: response.status, json: response.body.to_s
  end

  def show
    response = HTTP.get("#{base_path}/#{params[:id]}")
    render status: response.status, json: response.body.to_s
  end

  def create
    response =
      HTTP.post(base_path,
        headers: { 'Content-Type' => 'application/json' },
        body: params.permit!.to_json)
    render status: response.status, json: response.body.to_s
  end

  def update
    response =
      HTTP.patch("#{base_path}/#{params[:id]}",
        headers: { 'Content-Type' => 'application/json' },
        body: params.permit!.to_json)
    render status: response.status, json: response.body.to_s
  end

  def destroy
    response = HTTP.delete("#{base_path}/#{params[:id]}")
    render status: response.status, json: response.body.to_s
  end

  private

  def base_for_find_objects
    []
  end

end
