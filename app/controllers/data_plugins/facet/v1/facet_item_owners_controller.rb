class DataPlugins::Facet::V1::FacetItemOwnersController < Api::V1::BaseController

  before_action :find_facet_item, only: [:link_facet_item, :unlink_facet_item]
  before_action :find_owner

  # :owner_type/:owner_id/facet_items/:facet_item_id
  def link_facet_item
    result = @facet_item.link_owner(@owner)

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
    unless @facet_item.facet_item_owners.where(owner: @owner).exists?
      head :not_found
      return
    end

    result = @facet_item.unlink_owner(@owner)

    if result == true
      head 200
    elsif result == false
      head :unprocessable_entity
    else # returns :not_found :-)
      head result
    end
  end

  private

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
      when 'offers'
        DataModules::Offer::Offer.find(params[:owner_id])
      end
  end

end
