class Api::V1::TodosController < Api::V1::EntriesBaseController

  private

  def base_for_find_objects
    Todo.with_annotation.with_entries
  end

  def custom_filter_whitelist
    [:title, :description, :short_description].map(&:to_s).freeze
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    case filter.to_sym
      when :title, :description, :short_description
        objects.
          where("orgas.#{filter} LIKE ? OR events.#{filter} LIKE ?",
            "%#{filter_criterion}%", "%#{filter_criterion}%")
      else
        objects
    end
  end

  def do_includes!(objects)
    objects.grouped_by_entries.includes(:entry)
  end

end
