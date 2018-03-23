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
        offers: amount_of_offers(area),
        todos: Annotation.grouped_by_entries.with_entries.by_area(area).count.count,
        chapters: amount_of_chapters(area)
      }
    }
    render json: meta_hash
  end

  private

  def amount_of_chapters(area)
    AreaChapterConfig.active.by_area(area).count
  end

  def amount_of_offers(area)
    DataModules::Offer::Offer.by_area(area).count
  end

end
