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

      def facet_params(params)
        params.permit(:title)
      end

      def save_facet(params)
        facet = find_or_initialize_by(id: params[:id])
        facet.assign_attributes(facet_params(params))
        facet.save!
        facet
      end
    end

    def facet_items_to_hash
      items = facet_items.select { |item| item.parent_id == nil }
      items.map { |item| item.to_hash(attributes: item.class.default_attributes_for_json) }
    end

  end
end
