class Api::V1::TodosController < Api::V1::EntriesBaseController

  private

  def base_for_find_objects
    Todo.with_annotation.with_entries
  end

  def do_includes!(objects)
    objects.includes(:entry).group(:entry_id, :entry_type)
  end

end
