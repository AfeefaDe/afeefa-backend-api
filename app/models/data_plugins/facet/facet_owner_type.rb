module DataPlugins::Facet
  class FacetOwnerType < ApplicationRecord
    belongs_to :facet
  end
end
