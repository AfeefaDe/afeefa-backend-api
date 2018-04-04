class DataModules::FeNavigation::V1::FeNavigationController < Api::V1::BaseController

  skip_before_action :find_objects

  def show
    navigation = DataModules::FeNavigation::FeNavigation.by_area(current_api_v1_user.area).first
    render json: navigation.to_hash
  end

end
