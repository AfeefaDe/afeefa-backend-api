class Api::V1::EntriesBaseController < Api::V1::BaseController

  private

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
    objects =
      objects.includes(:annotations).includes(:locations).includes(:contact_infos).includes(:category).
        includes(:sub_category).includes(:parent).includes(:children)
    objects
  end

end
