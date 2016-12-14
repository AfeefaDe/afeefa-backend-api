class Api::V1::AnnotationResource < Api::V1::BaseResource
  attributes :title, :created_at, :updated_at

  has_many :entries, polymorphic: true
end
