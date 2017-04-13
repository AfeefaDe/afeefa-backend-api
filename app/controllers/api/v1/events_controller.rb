class Api::V1::EventsController < Api::V1::EntriesBaseController

  def custom_filter_whitelist
    [:date].map(&:to_s).freeze
  end

  def default_filter
    { date: :upcoming }
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    now = Time.current
    objects =
      case filter.to_sym
        when :date
          case filter_criterion.to_sym
            when :upcoming
              objects.
                where.not(date_start: nil).where.not(date_start: '').
                where('date_start > ?', now).or(objects.where('date_start = ?', now))
            when :past
              objects.
                where.not(date_end: nil).where.not(date_end: '').
                where('date_end < ?', now).or(objects.where('date_end = ?', now))
            when :running
              objects.
                where('date_start < ?', now).or(objects.where('date_start = ?', now)).
                or(objects.where(date_start: nil)).
                or(objects.where(date_start: '')).
                where('date_end > ?', now).or(objects.where('date_end = ?', now)).
                or(objects.where(date_end: nil)).
                or(objects.where(date_end: ''))
            else
              objects
          end
      end
    objects
  end

end
