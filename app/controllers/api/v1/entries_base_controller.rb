class Api::V1::EntriesBaseController < Api::V1::BaseController

  private

  def do_includes!(objects)
    objects =
      objects.includes(:annotations).includes(:locations).includes(:contact_infos).includes(:category).
        includes(:sub_category).includes(:parent).includes(:children)
    objects
  end

end
