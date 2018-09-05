require 'http'

class Api::V1::ChaptersController < Api::V1::BaseController

  include DeviseTokenAuth::Concerns::SetUserByToken
  include NoCaching
  include ChaptersApi

  skip_before_action :authenticate_api_v1_user!, only: :show

  respond_to :json

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
    chapter_ids =
      AreaChapterConfig.active.by_area(current_api_v1_user.area).pluck(:chapter_id)
    if chapter_ids.present?
      response = HTTP.get("#{base_path}?ids=#{chapter_ids.join(',')}")
      render status: response.status, json: response.body.to_s
    else
      render json: []
    end
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
    if 201 == response.status
      chapter = JSON.parse(response.body.to_s)
      config =
        ChapterConfig.new(
          chapter_id: chapter['id'],
          creator_id: current_api_v1_user.id,
          last_modifier_id: current_api_v1_user.id,
          active: true)
      if config.save
        area_config = AreaChapterConfig.new(area: current_api_v1_user.area, chapter_config_id: config.id)
        if area_config.save
          render status: response.status, json: chapter
          return
        end
      end
    end
    # TODO: Handle errors!
    render status: :unprocessable_entity
  end

  def update
    response =
      HTTP.patch("#{base_path}/#{params[:id]}",
        headers: { 'Content-Type' => 'application/json' },
        body: params.permit!.to_json)
    if 200 == response.status
      config = ChapterConfig.find_by(chapter_id: params[:id])
      # TODO: Should we update the area on chapter update?
      if config.update(last_modifier_id: current_api_v1_user.id)
        render status: response.status, json: response.body.to_s
        return
      end
    end
    # TODO: Handle errors!
    render status: :unprocessable_entity
  end

  def destroy
    response = HTTP.delete("#{base_path}/#{params[:id]}")
    if 204 == response.status
      config = ChapterConfig.find_by(chapter_id: params[:id])
      area_config = AreaChapterConfig.find_by(chapter_config_id: config.id)
      if config.destroy && area_config.destroy
        render status: response.status, json: response.body.to_s
        return
      end
      # TODO: Handle errors!
    end
    # TODO: Handle errors!
    render status: :unprocessable_entity
  end

  private

  def base_for_find_objects
    []
  end

end
