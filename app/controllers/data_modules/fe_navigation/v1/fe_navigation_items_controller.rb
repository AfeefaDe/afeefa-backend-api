class DataModules::FeNavigation::V1::FeNavigationItemsController < Api::V1::BaseController

  include HasLinkedOwners

  before_action :find_navigation, only: [:create]
  before_action :find_navigation_item, except: [:create]

  # fe_navigation_items
  def create
    params[:navigation_id] = @navigation.id
    navigation_item = DataModules::FeNavigation::FeNavigationItem.save_navigation_item(params)
    render status: :created, json: navigation_item
  end

  # fe_navigation_items/:id
  def update
    navigation_item = DataModules::FeNavigation::FeNavigationItem.save_navigation_item(params)
    render status: :ok, json: navigation_item
  end

  # fe_navigation_items/:id
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
    DataModules::FeNavigation::FeNavigationItem.
      includes(:navigation).
      where(fe_navigations: {area: current_api_v1_user.area}, parent_id: nil)
  end

  def find_navigation
    @navigation = DataModules::FeNavigation::FeNavigation.by_area(current_api_v1_user.area).first
  end

  def find_navigation_item
    find_navigation
    @item = DataModules::FeNavigation::FeNavigationItem.find(params[:id])
    @item_owners = @item.navigation_item_owners
  end

  def custom_find_owner
    @owner =
      case params[:owner_type]
      when 'facet_items'
        DataPlugins::Facet::FacetItem.find(params[:owner_id])
      end
  end

end
