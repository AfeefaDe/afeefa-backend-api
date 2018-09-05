module LazySerializable

  extend ActiveSupport::Concern

  def serialize_lazy(annotations: false, facets: true)
    params = {params: {facet_items:facets, navigation_items:facets}}
    hash = lazy_serializer.new(self, params).serializable_hash[:data]
    if annotations
      annotations = AnnotationSerializer.new(self.annotations).serializable_hash[:data]
      hash[:relationships][:annotations] = annotations
    end
    hash
  end

  def lazy_serializer
    raise NotImplementedError, "please implement the serializer factor for #{self}"
  end

end
