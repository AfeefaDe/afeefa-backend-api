class Api::V1::EntriesBaseController < Api::V1::BaseController

  private

  def apply_custom_filter!(filter, filter_criterion, objects)
    objects =
      case filter.to_sym
        when :area
          objects.by_area(filter_criterion)
        else
          objects
      end
    objects
  end

  def filter_whitelist
    %w(title description short_description).freeze
  end

  def custom_filter_whitelist
    %w(area).freeze
  end

  def default_filter
    { area: current_api_v1_user.area }
  end

end
