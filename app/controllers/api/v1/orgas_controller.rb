class Api::V1::OrgasController < Api::V1::BaseController

  # def destroy
  #   # binding.pry
  #   super
  # end

  def index
    jsonapi_render json: Orga.without_root.undeleted.to_a
  end

  def show
    jsonapi_render json: Orga.without_root.undeleted.find(params[:id])
  end

end
