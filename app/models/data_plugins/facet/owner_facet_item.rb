module DataPlugins::Facet
  class OwnerFacetItem < ApplicationRecord

    belongs_to :facet_item
    belongs_to :owner, polymorphic: true

  end
end
