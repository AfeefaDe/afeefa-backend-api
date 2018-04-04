module DataPlugins::Facet
  class FacetItem < ApplicationRecord
    include Jsonable
    include DataPlugins::Facet::Concerns::ActsAsFacetItem
    include Translatable

    # ASSOCIATIONS
    belongs_to :facet
    belongs_to :parent, class_name: FacetItem
    has_many :sub_items, class_name: FacetItem, foreign_key: :parent_id, dependent: :destroy

    has_many :facet_item_owners, class_name: FacetItemOwner, dependent: :destroy

    has_many :events, -> { by_area(Current.user.area) }, through: :facet_item_owners,
      source: :owner, source_type: 'Event'
    has_many :orgas, -> { by_area(Current.user.area) }, through: :facet_item_owners,
      source: :owner, source_type: 'Orga'
    has_many :offers, -> { by_area(Current.user.area) }, through: :facet_item_owners,
      source: :owner, source_type: 'DataModules::Offer::Offer'

    def owners
      events + orgas + offers
    end

    # VALIDATIONS
    validates :title, length: { maximum: 255 }
    validates :color, length: { maximum: 255 }

    validates :facet_id, presence: true
    validates :parent_id, presence: true, allow_nil: true
    validate :validate_facet_and_parent

    # SAVE HOOKS
    after_save :move_sub_items_to_new_facet
    after_save :move_owners_to_new_parent

    # CLASS METHODS
    class << self
      def translatable_attributes
        %i(title)
      end

      def translation_key_type
        'facet_item'
      end

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

    def link_owner(owner)
      if facet_item_owners.where(owner: owner).exists?
        return false
      end

      if !facet_supports_type_of_owner?(owner)
        return false
      end

      FacetItemOwner.create(
        owner: owner,
        facet_item_id: id
      )

      # link parent too
      if parent
        FacetItemOwner.find_or_create_by(
          owner: owner,
          facet_item_id: parent.id
        )
      end

      true
    end

    def unlink_owner(owner)
      facet_item_owner = facet_item_owners.where(owner: owner).first

      return false unless facet_item_owner

      facet_item_owners.delete(facet_item_owner)

      # unlink subitems too
      unlink_sub_items(owner)

      true
    end

    def sub_items_to_hash
      sub_items.map { |item| item.to_hash(attributes: item.class.default_attributes_for_json, relationships: nil) }
    end

    def owners_to_hash
      owners.map { |owner| owner.to_hash(attributes: 'title', relationships: nil) }
    end

    private

    def validate_facet_and_parent
      unless Facet.exists?(facet_id)
        return errors.add(:facet_id, 'Kategorie existiert nicht.')
      end

      validate_parent_relation

      # cannot set parent with different facet_id
      parent = self.class.find_by_id(parent_id)
      if parent && parent.facet_id != facet_id
        return errors.add(:parent_id, 'Ein übergeordnetes Attribut muss zur selben Kategorie gehören.')
      end
    end

    def move_sub_items_to_new_facet
      sub_items.update(facet_id: self.facet_id)
    end

    def facet_supports_type_of_owner?(owner)
      type = owner.class.to_s.split('::').last
      facet.owner_types.where(owner_type: type).exists?
    end

    # ActsAsFacetItem

    def item_owners(item = nil)
      item = item || self
      item.facet_item_owners
    end

    def items_of_owners(owner)
      owner.facet_items
    end

    def message_parent_nonexisting
      'Übergeordnetes Attribut existiert nicht.'
    end

    def message_item_sub_of_sub
      'Ein Attribut kann nicht Unterattribut eines Unterattributs sein.'
    end

    def message_sub_of_itself
      'Ein Attribut kann nicht sein Unterattribut sein.'
    end

    def message_sub_cannot_be_nested
      'Ein Attribut mit Unterattributen kann nicht verschachtelt werden.'
    end

    include DataModules::FeNavigation::Concerns::HasFeNavigationItems

  end
end
