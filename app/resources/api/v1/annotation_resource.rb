class Api::V1::AnnotationResource < Api::V1::BaseResource
  attributes :title, :created_at, :updated_at

  has_one :annotatable, polymorphic: true
end
