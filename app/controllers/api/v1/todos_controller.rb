class Api::V1::TodosController < Api::V1::EntriesController


  def index
    area = current_api_v1_user.area

    objects = Annotation.
      by_area(current_api_v1_user.area).
      group_by_entry.order(:id)

    if filter_params[:annotation_category_id].present?
      objects = objects.where(annotation_category_id: filter_params[:annotation_category_id])
    end

    annotations = objects.all
    entries = Annotation.entries(annotations, 'lazy_includes')
    todos = entries.map do |item|
      item_hash =
        if item.is_a?(Event)
          EventSerializer.new(item).serializable_hash[:data]
        elsif item.is_a?(Orga)
          OrgaSerializer.new(item).serializable_hash[:data]
        elsif item.is_a?(DataModules::Offer::Offer)
          OfferSerializer.new(item).serializable_hash[:data]
        end
      # need to inject annotation since jsonapi spec does not allow relation attributes
      annotations = AnnotationSerializer.new(item.annotations).serializable_hash[:data]
      item_hash[:relationships][:annotations] = annotations
      item_hash
      # item.to_hash(
      #   attributes: item.class.lazy_attributes_for_json,
      #   relationships: item.class.lazy_relations_for_json + [:annotations]
      # )
    end

    render status: :ok, json: { data: todos.as_json }
  end

end
