module DataPlugins::Facet
  class FacetItem < ApplicationRecord

    include Jsonable

    # ASSOCIATIONS
    belongs_to :facet
    belongs_to :parent, class_name: FacetItem
    # TODO: Should the children be destroyed?
    has_many :sub_items, class_name: FacetItem, foreign_key: :parent_id, dependent: :destroy

    has_many :owner_facet_items, class_name: DataPlugins::Facet::OwnerFacetItem, dependent: :destroy

    def owners
      owner_facet_items.map(&:owner)
    end

    # VALIDATIONS
    validates :title, length: { maximum: 255 }
    validates :color, length: { maximum: 255 }

    validates :facet_id, presence: true
    validates :parent_id, presence: true, allow_nil: true
    validate :validate_facet_and_parent

    # SAVE HOOKS
    after_save :move_sub_items_to_new_facet

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(title color facet_id parent_id count_owners).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(sub_items).freeze
      end

      def count_relation_whitelist_for_json
        %i(owners).freeze
      end

      def facet_item_params(params)
        # facet_id is a route param, hence we introduce new_facet_id to allow facet_id update
        params.permit(:title, :color, :parent_id, :new_facet_id, :facet_id)
      end

      def save_facet_item(params)
        facet_item = find_or_initialize_by(id: params[:id])
        facet_item.assign_attributes(facet_item_params(params))
        facet_item.save!
        facet_item
      end
    end

    def validate_facet_and_parent
      if facet_id
        return errors.add(:facet_id, 'Kategorie existiert nicht.') unless DataPlugins::Facet::Facet.exists?(facet_id)
      end

      if parent_id
        return errors.add(:parent_id, 'Übergeordnetes Attribut existiert nicht.') unless DataPlugins::Facet::FacetItem.exists?(parent_id)
      end

      if parent_id
        # cannot set parent to self
        if parent_id == id
          return errors.add(:parent_id, 'Ein Attribut kann nicht sein Unterattribut sein.')
        end

        # cannot set parent if sub_items present
        if sub_items.any?
          return errors.add(:parent_id, 'Ein Attribut mit Unterattributen kann nicht verschachtelt werden.')
        end

        parent = DataPlugins::Facet::FacetItem.find_by_id(parent_id)

        # cannot set parent to sub_item
        if parent.parent_id
          return errors.add(:parent_id, 'Ein Attribut kann nicht Unterattribut eines Unterattributs sein.')
        end

        # cannot set parent with different facet_id
        if parent.facet_id != facet_id
          return errors.add(:parent_id, 'Ein übergeordnetes Attribut muss zur selben Kategorie gehören.')
        end
      end
    end

    def move_sub_items_to_new_facet
      sub_items.update(facet_id: self.facet_id)
    end

    def sub_items_to_hash
      sub_items.map { |item| item.to_hash(attributes: item.class.default_attributes_for_json, relationships: nil) }
    end

    def owners_to_hash
      owners.map { |owner| owner.to_hash(attributes: 'title', relationships: nil) }
    end

  end
end
