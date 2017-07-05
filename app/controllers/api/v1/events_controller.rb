class Api::V1::EventsController < Api::V1::EntriesBaseController

  def custom_filter_whitelist
    (super.deep_dup + %w(date)).freeze
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    objects = super
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
        else
          objects
      end
    objects
  end

end
