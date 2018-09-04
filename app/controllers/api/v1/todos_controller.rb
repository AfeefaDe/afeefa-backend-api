class Api::V1::TodosController < Api::V1::EntriesController


  def index
    area = current_api_v1_user.area

    objects = Annotation.
      by_area(current_api_v1_user.area).
      order(updated_at: :desc, id: :desc).
      group_by_entry.order(:id)

    if filter_params[:annotation_category_id].present?
      objects = objects.where(annotation_category_id: filter_params[:annotation_category_id])
    end

    annotations = objects.all
    entries = Annotation.entries(annotations)
    todos = entries.map do |item|
      item.serialize_lazy(annotations: true, facets: false)
    end

    render status: :ok, json: { data: todos }
  end

end
