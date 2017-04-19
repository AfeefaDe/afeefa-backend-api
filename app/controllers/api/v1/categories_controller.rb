class Api::V1::CategoriesController < Api::V1::BaseController

  private

  def do_includes!(objects)
    objects =
      objects.includes(:parent)
    objects
  end

end
