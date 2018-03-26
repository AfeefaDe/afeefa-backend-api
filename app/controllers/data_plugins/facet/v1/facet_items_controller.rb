class DataPlugins::Facet::V1::FacetItemsController < Api::V1::BaseController

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
    if @facet_item.destroy
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  # facets/:facet_id/facet_items/:id/owners
  def get_linked_owners
    render status: :ok, json: @facet_item.owners_to_hash
  end

  # facets/:facet_id/facet_items/:id/owners
  def link_owners
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        owner_ids = params[:owners]
        one_created = false
        owner_ids.each do |owner_config|
          params[:owner_id] = owner_config[:owner_id]
          params[:owner_type] = owner_config[:owner_type]

          find_owner

          created = @facet_item.link_owner(@owner)
          one_created = one_created || created
        end
        if one_created
          head 201
        else
          head :unprocessable_entity
        end
      end
    rescue
      head :unprocessable_entity
    end
  end

  # facets/:facet_id/facet_items/:id/owners
  def unlink_owners
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        owner_ids = params[:owners]
        one_removed = false
        owner_ids.each do |owner_config|
          params[:owner_id] = owner_config[:owner_id]
          params[:owner_type] = owner_config[:owner_type]

          find_owner

          removed = @facet_item.unlink_owner(@owner)
          one_removed = one_removed || removed
        end
        if one_removed
          head 200
        else
          head :unprocessable_entity
        end
      end
    rescue
      head :unprocessable_entity
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
    @facet_item = DataPlugins::Facet::FacetItem.find(params[:id])
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
    unless @owner
      raise ActiveRecord::RecordNotFound,
        "Element mit ID #{params[:owner_id]} konnte für Typ #{params[:owner_type]} nicht gefunden werden."
    end
  end

end
