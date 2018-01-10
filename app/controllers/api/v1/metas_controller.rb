require 'http'

class Api::V1::MetasController < ApplicationController

  include DeviseTokenAuth::Concerns::SetUserByToken
  include NoCaching
  include ChaptersApi

  respond_to :json

  before_action :authenticate_api_v1_user!

  def index
    area = current_api_v1_user.area

    meta_hash = {
      meta: {
        orgas: Orga.by_area(area).count,
        events: {
          all: Event.by_area(area).count,
          past: Event.by_area(area).past.count,
          upcoming: Event.by_area(area).upcoming.count
        },
        todos: Annotation.grouped_by_entries.with_entries.by_area(area).count.count,
        chapters: amount_of_chapters(area)
      }
    }
    render json: meta_hash
  end

  private

  def amount_of_chapters(area)
    # TODO: use param area if its is supported by chapters api
    response = HTTP.get("#{base_path}/meta", headers: { 'Content-Type' => 'application/json' })
    JSON.parse(response.body.to_s)['amount']
  end

end
