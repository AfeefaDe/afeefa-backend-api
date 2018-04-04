class DataPlugins::Facet::V1::FacetsController < Api::V1::BaseController

  skip_before_action :find_objects, except: [:index, :show]
  before_action :find_facet, only: [:update, :destroy]

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

  def do_includes!(objects)
    objects =
      objects.includes(:owner_types, :facet_items, {
        facet_items: [
          {sub_items: [:events, :orgas, :offers]},
          :events,
          :orgas,
          :offers
        ]
      })
    objects
  end

  def base_for_find_objects
    DataPlugins::Facet::Facet.all
  end

  def find_facet
    @facet = DataPlugins::Facet::Facet.find(params[:id])
  end

end
