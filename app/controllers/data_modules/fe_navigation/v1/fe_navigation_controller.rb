class DataModules::FeNavigation::V1::FeNavigationController < Api::V1::BaseController
  skip_before_action :find_objects

  def show
    navigation =
      DataModules::FeNavigation::FeNavigation.
        includes(
          [
            {
              navigation_items:
                [
                  {
                    sub_items: [:sub_items]
                  }
                ]
            }
          ]
        ).
        by_area(current_api_v1_user.area).
        take
    render json: navigation.to_hash
  end

  def set_ordered_navigation_items
    if ordered_navigation_item_params.try(:any?)
      navigation = DataModules::FeNavigation::FeNavigation.by_area(current_api_v1_user.area).take
      navigation.order_navigation_items!(ordered_navigation_item_params)
      head :ok
    else
      head :no_content
    end
  rescue => exception
    raise exception if Rails.env.test?
    Rails.logger.error(exception)
    head :unprocessable_entity
  end

  private

  def ordered_navigation_item_params
    params.fetch(:navigation_item_ids, [])
  end
end
