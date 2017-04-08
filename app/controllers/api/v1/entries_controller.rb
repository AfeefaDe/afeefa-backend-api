class Api::V1::EntriesController < Api::V1::TodosController

  private

  def base_for_find_objects
    Entry.with_entries
  end

end
