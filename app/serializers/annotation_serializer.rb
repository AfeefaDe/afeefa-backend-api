class AnnotationSerializer
  include FastJsonapi::ObjectSerializer
  set_type :annotations
  attributes :detail, :annotation_category_id, :created_at, :updated_at
end
