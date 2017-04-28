class Api::V1::TodosController < Api::V1::EntriesController

  private

  def to_hash_method
    :to_todos_hash
  end

  def base_for_find_objects
    Annotation.with_annotation_category.with_entries
  end

  def do_includes!(objects)
    objects.grouped_by_entries.includes(:entry)
  end

end
