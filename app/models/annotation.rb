class Annotation < ApplicationRecord
  belongs_to :annotateable, polymorphic: true
end
