class AnnotationSerializer
  include FastJsonapi::ObjectSerializer
  set_type :annotations

  attribute :detail
  attribute :annotation_category_id
  attribute :created_at, if: Proc.new { |record, params| !params[:public] == true }
  attribute :updated_at, if: Proc.new { |record, params| !params[:public] == true }
end
