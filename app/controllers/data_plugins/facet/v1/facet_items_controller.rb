class DataPlugins::Facet::V1::FacetItemsController < Api::V1::BaseController

  skip_before_action :find_objects, except: [:index, :show]
  before_action :find_facet_item, only: [:update, :destroy]
  before_action :find_owner, only: %i(get_linked_facet_items link_facet_item unlink_facet_item)

  def create
    facet = DataPlugins::Facet::FacetItem.save_facet_item(params)
    render status: :created, json: facet
  end

  def update
    facet = DataPlugins::Facet::FacetItem.save_facet_item(params)
    render status: :ok, json: facet
  end

  def destroy
    if @facet_item.destroy
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  def link_facet_item
    if get_facet_item_relation(params[:facet_item_id])
      head 400
      return
    end

    result =
    DataPlugins::Facet::OwnerFacetItem.create(
        owner: @owner,
        facet_item_id: params[:facet_item_id]
      )
    if result
      head 201
    else
      head 500
    end
  end

  def get_linked_facet_items
    render status: :ok, json: @owner.facet_items
  end

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

  def base_for_find_objects
    DataPlugins::Facet::FacetItem.where(facet_id: params[:facet_id])
  end

  def get_facet_item_relation(facet_item_id)
    DataPlugins::Facet::OwnerFacetItem.find_by(
      owner: @owner,
      facet_item_id: facet_item_id
    )
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    objects =
      case filter.to_sym
      when :facet_id
        objects.where(facet_id: filter_criterion)
      else
        objects
      end
    objects
  end

  def custom_filter_whitelist
    %w(facet_id).freeze
  end

  def get_model_class_for_controller
    DataPlugins::Facet::FacetItem
  end

  def find_facet_item
    @facet_item = DataPlugins::Facet::FacetItem.find(params[:id])
  end

  def find_owner
    @owner =
      case params[:owner_type]
      when 'orgas'
        Orga.find(params[:owner_id])
      when 'events'
        Event.find(params[:owner_id])
      end
    unless @owner
      raise ActiveRecord::RecordNotFound,
        "Element mit ID #{params[:owner_id]} konnte für Typ #{params[:owner_type]} nicht gefunden werden."
    end
  end

end
