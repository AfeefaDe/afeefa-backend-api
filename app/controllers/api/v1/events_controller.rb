class Api::V1::EventsController < Api::V1::BaseController

  def filter_whitelist
    %w(title description short_description).freeze
  end

  def custom_filter_whitelist
    %w(date).freeze
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    now = Time.current
    objects =
      case filter.to_sym
        when :date
          case filter_criterion.to_sym
            when :upcoming
              # date_start > today 00:00
              # date_end > today 00:00
              objects.
                where.not(date_start: [nil, '']).
                where('date_start > ?', now).
                or(objects.
                  where('date_start = ?', now)).
                or(objects.
                  where('date_end > ?', now))
            when :past
              # kein date_end und date_start < today 00:00
              # hat date_end und date_end < today 00:00
              objects.
                where(date_end: nil).
                where.not(date_start: [nil, '']).
                where('date_start < ?', now).
                or(objects.
                  where(date_end: '').
                  where.not(date_start: [nil, '']).
                  where('date_start < ?', now)).
                or(objects.
                  where.not(date_end: [nil, '']).
                  where('date_end < ?', now))
            else
              objects
          end
      end
    objects
  end

end
