class Api::V1::LocationsController < Api::V1::BaseController

  private

  def base_for_find_objects
    DataPlugins::Location::Location.all
  end

end
