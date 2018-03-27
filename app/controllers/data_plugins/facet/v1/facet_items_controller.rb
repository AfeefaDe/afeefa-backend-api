class DataPlugins::Facet::V1::FacetItemsController < Api::V1::BaseController

  include HasLinkedOwners

  skip_before_action :find_objects, except: [:index, :show]
  before_action :find_facet, only: [:index, :create]
  before_action :find_facet_item, except: [:index, :create]

  # facets/:facet_id/facet_items
  def create
    facet_item = DataPlugins::Facet::FacetItem.save_facet_item(params)
    render status: :created, json: facet_item
  end

  # facets/:facet_id/facet_items/:id
  def update
    # need to introduce new_facet_id since facet_id is already bound to the route
    if params.has_key?(:new_facet_id)
      params[:facet_id] = params[:new_facet_id]
      params.delete :new_facet_id
    end

    facet_item = DataPlugins::Facet::FacetItem.save_facet_item(params)
    render status: :ok, json: facet_item
  end

  # facets/:facet_id/facet_items/:id
  def destroy
    if @item.destroy
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  private

  def do_includes!(objects)
    objects =
      objects.includes(:sub_items)
    objects
  end

  def base_for_find_objects
    DataPlugins::Facet::FacetItem.where(facet_id: params[:facet_id], parent_id: nil)
  end

  def find_facet
    @facet = DataPlugins::Facet::Facet.find(params[:facet_id])
  end

  def find_facet_item
    find_facet
    @item = DataPlugins::Facet::FacetItem.find(params[:id])
    @item_owners = @item.facet_item_owners
  end

end
