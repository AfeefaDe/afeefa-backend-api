class AnnotationAbleRelation < ApplicationRecord
  belongs_to :annotation
  belongs_to :entry, polymorphic: true
end
