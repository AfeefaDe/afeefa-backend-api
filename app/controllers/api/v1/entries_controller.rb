class Api::V1::EntriesController < Api::V1::EntriesBaseController

  private

  def base_for_find_objects
    Entry.with_entries
  end

  def filter_whitelist
    %w().freeze
  end

  def custom_filter_whitelist
    %w(area title description short_description).freeze
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    objects =
      case filter.to_sym
        when :area
          objects.
            where("orgas.#{filter} = ? OR events.#{filter} = ?",
              filter_criterion, filter_criterion)
        when :title, :description, :short_description
          objects.
            where("orgas.#{filter} LIKE ? OR events.#{filter} LIKE ?",
              "%#{filter_criterion}%", "%#{filter_criterion}%")
        else
          objects
      end
    objects
  end

  def do_includes!(objects)
    objects.includes(:entry)
  end

end
