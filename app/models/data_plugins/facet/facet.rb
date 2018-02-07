module DataPlugins::Facet
  class Facet < ApplicationRecord

    include Jsonable

    # ASSOCIATIONS
    has_many :facet_items, dependent: :destroy
    has_many :owner_facet_items, class_name: DataPlugins::Facet::OwnerFacetItem, through: :facet_items
    def owners
      owner_facet_items.map(&:owner)
    end
    # VALIDATIONS
    validates :title, length: { maximum: 255 }

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(title).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(facet_items).freeze
      end
    end

  end
end
