require 'http'

class Api::V1::ChaptersController < ApplicationController

  include DeviseTokenAuth::Concerns::SetUserByToken
  include NoCaching

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
    @api_path = Settings.chapters_api_path || 'http://localhost:3010/chapters'
  end

  def index
    render json: JSON.parse(HTTP.get(@api_path).to_s)
  end

  def show
    render json: JSON.parse(HTTP.get("#{@api_path}/#{params[:id]}").to_s)
  end

  def create
    pp params.permit!.to_json
    render json: JSON.parse(HTTP.post(@api_path, body: params.permit!.to_json)).to_s
  end

  def update
    render json: JSON.parse(HTTP.patch("#{@api_path}/#{params[:id]}", params).to_s)
  end

  def destroy
    response = HTTP.delete("#{@api_path}/#{params[:id]}").to_s
    if response.blank?
      head :no_content
    else
      render json: response
    end
  end

end
