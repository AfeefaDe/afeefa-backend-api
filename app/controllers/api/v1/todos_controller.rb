class Api::V1::TodosController < Api::V1::EntriesController

  def index
    objects = Annotation.by_area(current_api_v1_user.area).group_by_entry.order(:id)

    if filter_params[:annotation_category_id].present?
      objects = objects.where(annotation_category_id: filter_params[:annotation_category_id])
    end

    annotations = objects.all
    entries = Annotation.entries(annotations)
    render json: {
      data: entries.map { |item| item.to_hash }
    }
  end

end
