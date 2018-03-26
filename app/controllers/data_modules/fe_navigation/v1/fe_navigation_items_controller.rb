class DataModules::FENavigation::V1::FENavigationItemsController < Api::V1::BaseController

  skip_before_action :find_objects, except: [:index, :show]
  before_action :find_navigation, only: [:index, :create]
  before_action :find_navigation_item, except: [:index, :create]
  before_action :find_owner, only: [:link_owner, :unlink_owner]

  # fe_navigation_items
  def create
    params[:navigation_id] = @navigation.id
    navigation_item = DataModules::FENavigation::FENavigationItem.save_navigation_item(params)
    render status: :created, json: navigation_item
  end

  # fe_navigation_items/:id
  def update
    params[:navigation_id] = @navigation.id
    navigation_item = DataModules::FENavigation::FENavigationItem.save_navigation_item(params)
    render status: :ok, json: navigation_item
  end

  # fe_navigation_items/:id
  def destroy
    if @navigation_item.destroy
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  # fe_navigation_items/:id/owners
  def link_owner
    result = @navigation_item.link_owner(@owner)

    if result
      head 201
    else
      head :unprocessable_entity
    end
  end

  # :owner_type/:owner_id/facet_items/:facet_item_id
  def unlink_owner
    unless @navigation_item.navigation_item_owners.where(owner: @owner).exists?
      head :not_found
      return
    end

    result = @navigation_item.unlink_owner(@owner)

    if result == true
      head 200
    else
      head :unprocessable_entity
    end
  end

  # fe_navigation_items/:id/owners
  def get_linked_owners
    render status: :ok, json: @navigation_item.owners_to_hash
  end

  private

  def do_includes!(objects)
    objects =
      objects.includes(:sub_items)
    objects
  end

  def base_for_find_objects
    DataModules::FENavigation::FENavigationItem.
      includes(:navigation).
      where(fe_navigations: {area: current_api_v1_user.area}, parent_id: nil)
  end

  def find_navigation
    @navigation = DataModules::FENavigation::FENavigation.by_area(current_api_v1_user.area).first
  end

  def find_navigation_item
    find_navigation
    @navigation_item = DataModules::FENavigation::FENavigationItem.find(params[:id])
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
