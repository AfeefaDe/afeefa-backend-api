class DataPlugins::Facet::V1::FacetItemsController < Api::V1::BaseController

  skip_before_action :find_objects, except: [:index, :show]
  before_action :find_facet_item, only: [:update, :destroy]

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

  private

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

end
