class Api::V1::TodosController < Api::V1::EntriesController

  def custom_filter_whitelist
    (super.deep_dup + %w(annotation_category_id)).freeze
  end

  private

  def to_hash_method
    :to_todos_hash
  end

  def base_for_find_objects
    Annotation.with_entries
  end

  def do_includes!(objects)
    object = objects.grouped_by_entries.
      includes({orga: Orga.default_includes}).
      includes({event: Event.default_includes})
  end

end
