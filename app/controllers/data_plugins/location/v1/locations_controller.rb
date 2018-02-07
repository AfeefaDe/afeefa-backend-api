class DataPlugins::Location::V1::LocationsController < Api::V1::BaseController

  private

  def base_for_find_objects
    area = current_api_v1_user.area
    DataPlugins::Location::Location.selectable_in_area(area)
  end

end
