module Filter

  extend ActiveSupport::Concern

  private

  def apply_filter!(filter, filter_criterion, objects)
    objects =
      if filter_criterion.is_a?(Array)
        handle_array_filter(filter, filter_criterion, objects)
      else
        handle_search_terms(filter, filter_criterion, objects)
      end
    objects
  end

  def handle_array_filter(filter, filter_criterion, objects)
    tmp = objects
    filter_criterion.each do |element|
      tmp = apply_filter!(filter, element, tmp)
    end
    tmp
  end

  def handle_search_terms(filter, filter_criterion, objects)
    regex = /("[^"]+"|[^"\s]+)/
    matches = filter_criterion.scan(regex)
    tmp = objects
    matches.flatten.compact.each do |match|
      tmp = apply_search!(filter, match.remove(/\A"/).remove(/"\z/), tmp)
    end
    tmp
  end

  def apply_search!(filter, filter_criterion, objects)
    objects =
      if filter_criterion.present?
        custom_search_query(filter, filter_criterion, objects)
      else
        objects.none
      end
    objects
  end

  def custom_search_query(filter, filter_criterion, objects)
    objects.where("#{filter} LIKE ?", "%#{filter_criterion}%")
  end

end
