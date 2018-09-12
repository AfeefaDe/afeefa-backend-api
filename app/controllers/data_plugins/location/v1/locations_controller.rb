class DataPlugins::Location::V1::LocationsController < Api::V1::BaseController

  skip_before_action :find_objects

  def index
    area = current_api_v1_user.area

    locations = DataPlugins::Location::Location.includes(DataPlugins::Location::Location.default_includes).
    selectable_in_area(area).
    map do |location|
      location.to_hash(
        attributes: DataPlugins::Location::Location.default_attributes_for_json,
        relationships: DataPlugins::Location::Location.default_relations_for_json)
    end

    render status: :ok, json: { data: locations }
  end

  def show
    location = DataPlugins::Location::Location.find(params[:id])
    render status: :ok, json: location.as_json
  end

end
