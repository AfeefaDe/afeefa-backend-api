module DataPlugins::Facet
  class FacetItem < ApplicationRecord

    include Jsonable

    # ASSOCIATIONS
    belongs_to :facet
    belongs_to :parent, class_name: FacetItem
    # TODO: Should the children be destroyed?
    has_many :sub_items, class_name: FacetItem, foreign_key: :parent_id

    has_many :owner_facet_items, class_name: DataPlugins::Facet::OwnerFacetItem
    def owners
      owner_facet_items.map(&:owner)
    end

    # VALIDATIONS
    validates :title, length: { maximum: 255 }
    validates :color, length: { maximum: 255 }

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(title color).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(facet parent sub_items).freeze
      end

      def facet_item_params(params)
        params.permit(:title, :parent_id, :facet_id)
      end

      def save_facet_item(params)
        facet = find_or_initialize_by(id: params[:id])
        facet.assign_attributes(facet_item_params(params))
        facet.save!
        facet
      end
    end

  end
end
