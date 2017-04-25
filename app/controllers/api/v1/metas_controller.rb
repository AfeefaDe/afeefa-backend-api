class Api::V1::MetasController < ApplicationController

  include DeviseTokenAuth::Concerns::SetUserByToken
  include CustomHeaders

  respond_to :json

  before_action :authenticate_api_v1_user!

  def index
    meta_hash = {
      meta: {
        orgas: Orga.count,
        events: Event.count,
        todos: Todo.grouped_by_entries.count.count,
      }
    }
    render json: meta_hash
  end

end
