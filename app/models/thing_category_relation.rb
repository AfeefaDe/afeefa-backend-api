class ThingCategoryRelation < ApplicationRecord
  belongs_to :catable, polymorphic: true
  belongs_to :category
end
