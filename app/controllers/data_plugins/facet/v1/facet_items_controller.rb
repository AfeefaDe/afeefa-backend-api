class DataPlugins::Facet::V1::FacetItemsController < Api::V1::BaseController

  include HasLinkedOwners

  skip_before_action :find_objects, except: [:index, :show]
  before_action :find_facet, only: [:index, :create]
  before_action :find_facet_item, except: [:index, :create, :get_linked_facet_items, :link_facet_items]

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

  # :owner_type/:owner_id/facet_items
  def get_linked_facet_items
    find_owner

    render status: :ok, json: @owner.facet_items
  end

  # :owner_type/:owner_id/facet_items
  def link_facet_items
    find_owner

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        facet_item_ids = params[:facet_items] || [] # https://github.com/rails/rails/issues/26569
        @owner.facet_items.destroy_all
        facet_item_ids.each do |facet_item_id|
          facet_item = DataPlugins::Facet::FacetItem::find(facet_item_id)
          facet_item.link_owner(@owner)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  private

  def do_includes!(objects)
    objects =
      objects.includes([
        {sub_items: [:events, :orgas, :offers]},
        :events,
        :orgas,
        :offers
      ])
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
