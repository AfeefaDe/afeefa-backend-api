class Api::V1::EventsController < Api::V1::EntriesBaseController

  def filter_whitelist
    %w(title description short_description).freeze
  end

  def custom_filter_whitelist
    %w(date).freeze
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    objects =
      case filter.to_sym
        when :date
          case filter_criterion.to_sym
            when :upcoming
              objects.upcoming
            when :past
              objects.past
            else
              objects
          end
      end
    objects
  end

end
