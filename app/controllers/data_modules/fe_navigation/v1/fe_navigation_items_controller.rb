class DataModules::FeNavigation::V1::FeNavigationItemsController < Api::V1::BaseController
  include HasLinkedOwners

  before_action :find_navigation, only: [:create]
  before_action :find_navigation_item, except: [:create, :get_linked_navigation_items, :link_navigation_items]

  # fe_navigation_items
  def create
    params[:navigation_id] = @navigation.id
    navigation_item = DataModules::FeNavigation::FeNavigationItem.save_navigation_item(params)
    render status: :created, json: navigation_item
  end

  # fe_navigation_items/:id
  def update
    navigation_item = DataModules::FeNavigation::FeNavigationItem.save_navigation_item(params)

    if navigation_item.previous_changes.has_key?(:order)
      new_order = navigation_item.previous_changes['order'][1]
      # since the update of navigation item already created a fapi cache job
      # we can use update_all here and bypass the on save hook
      DataModules::FeNavigation::FeNavigationItem.
        where.not(id: navigation_item.id).
        where('`order` >= ?', new_order).
        update_all('`order` = `order` + 1')
    end

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

  # fe_navigation_items/:id/facet_items
  def get_linked_facet_items
    render status: :ok, json: @item.facet_items
  end

  # fe_navigation_items/:id/facet_items
  def link_facet_items
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        facet_item_ids = params[:facet_items] || [] # https://github.com/rails/rails/issues/26569
        @item.facet_items.destroy_all
        facet_item_ids.each do |facet_item_id|
          facet_item = DataPlugins::Facet::FacetItem::find(facet_item_id)
          @item.link_owner(facet_item)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  # :owner_type/:owner_id/fe_navigation_items
  def get_linked_navigation_items
    find_owner

    render status: :ok, json: @owner.navigation_items
  end

  # :owner_type/:owner_id/fe_navigation_items
  def link_navigation_items
    find_owner

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        navigation_item_ids = params[:navigation_items] || [] # https://github.com/rails/rails/issues/26569
        @owner.navigation_items.destroy_all
        navigation_item_ids.each do |navigation_item_id|
          navigation_item = DataModules::FeNavigation::FeNavigationItem::find(navigation_item_id)
          navigation_item.link_owner(@owner)
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
