class DataPlugins::Facet::V1::OwnerFacetItemsController < Api::V1::BaseController

  before_action :find_facet_item, only: [:link_facet_item, :unlink_facet_item]
  before_action :find_owner

  # :owner_type/:owner_id/facet_items/:facet_item_id
  def link_facet_item
    if get_facet_item_relation(params[:facet_item_id])
      head :unprocessable_entity
      return
    end

    if !facet_supports_type_of_owner
      head :unprocessable_entity
      return
    end

    result = DataPlugins::Facet::OwnerFacetItem.create(
      owner: @owner,
      facet_item_id: params[:facet_item_id]
    )
    if result
      head 201
    else
      head :unprocessable_entity
    end
  end

  # :owner_type/:owner_id/facet_items
  def get_linked_facet_items
    render status: :ok, json: @owner.facet_items
  end

  # :owner_type/:owner_id/facet_items/:facet_item_id
  def unlink_facet_item
    association = get_facet_item_relation(params[:facet_item_id])
    if association
      if association.destroy
        head 200
      else
        head 500
      end
    else
      head 404
    end
  end

  private

  def facet_supports_type_of_owner()
    type = @owner.class.to_s.split('::').last
    @facet_item.facet.owner_types.where(owner_type: type).exists?
  end

  def get_facet_item_relation(facet_item_id)
    DataPlugins::Facet::OwnerFacetItem.find_by(
      owner: @owner,
      facet_item_id: facet_item_id
    )
  end

  def find_facet_item
    @facet_item = DataPlugins::Facet::FacetItem.find(params[:facet_item_id])
  end

  def find_owner
    @owner =
      case params[:owner_type]
      when 'orgas'
        Orga.find(params[:owner_id])
      when 'events'
        Event.find(params[:owner_id])
      end
  end

end
