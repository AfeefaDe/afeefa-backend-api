module DataPlugins::Facet::Concerns::HasFacetItems

  extend ActiveSupport::Concern

  included do
    has_many :facet_item_owners, class_name: DataPlugins::Facet::FacetItemOwner, as: :owner, dependent: :destroy
    has_many :facet_items, class_name: DataPlugins::Facet::FacetItem, through: :facet_item_owners
    has_many :facets, class_name: DataPlugins::Facet::Facet, through: :facet_items
  end

  def facet_items_to_hash(attributes: nil, relationships: nil)
    facet_items.map { |item| item.to_hash(attributes: nil, relationships: nil) }
  end

  module ClassMethods
  end

end
