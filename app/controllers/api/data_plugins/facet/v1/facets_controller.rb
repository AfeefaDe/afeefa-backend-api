class Api::DataPlugins::Facet::V1::FacetsController < Api::V1::BaseController

  skip_before_action :find_objects
  before_action :find_facet, only: [:update, :destroy]

  def index
    render status: :ok, json: DataPlugins::Facet::Facet.all
  end

  def create
    facet = DataPlugins::Facet::Facet.save_facet(params)
    render status: :created, json: facet
  end

  def update
    facet = DataPlugins::Facet::Facet.save_facet(params)
    render status: :ok, json: facet
  end

  def destroy
    if @facet.destroy
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  private

  def find_facet
    @facet = DataPlugins::Facet::Facet.find(params[:id])
  end

end
