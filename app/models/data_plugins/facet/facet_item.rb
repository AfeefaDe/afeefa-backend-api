module DataPlugins::Facet
  class FacetItem < ApplicationRecord
    include Jsonable

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
      source: :owner, source_type: 'DataModules::Offer::Offer', class_name: DataModules::Offer::Offer

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
      return errors.add(:facet_id, 'Kategorie existiert nicht.') unless Facet.exists?(facet_id)

      if parent_id
        return errors.add(:parent_id, 'Übergeordnetes Attribut existiert nicht.') unless FacetItem.exists?(parent_id)
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

        parent = FacetItem.find_by_id(parent_id)

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
      if (sub_items.count)
        sub_items.each do |sub_item|
          facet_item_owner = sub_item.facet_item_owners.where(owner: owner).first
          if facet_item_owner
            sub_item.facet_item_owners.delete(facet_item_owner)
          end
        end
      end

      true
    end

    def sub_items_to_hash
      sub_items.map { |item| item.to_hash(attributes: item.class.default_attributes_for_json, relationships: nil) }
    end

    def owners_to_hash
      owners.map { |owner| owner.to_hash(attributes: 'title', relationships: nil) }
    end

    private

    def move_sub_items_to_new_facet
      sub_items.update(facet_id: self.facet_id)
    end

    def move_owners_to_new_parent
      if changes.key?('parent_id')
        old_parent_id = changes['parent_id'][0]
        if old_parent_id
          old_parent = FacetItem.find(old_parent_id)
          facet_item_owners.each do |facet_item_owner|
            # remove only from parent if no other sub association to that parent exists
            sub_facet_items_with_parent = 0
            facet_item_owner.owner.facet_items.each do |facet_item|
              if facet_item.parent_id == old_parent_id
                sub_facet_items_with_parent += 1
              end
            end
            if sub_facet_items_with_parent == 0
              facet_item_owner.owner.facet_items.delete(old_parent)
            end
          end
        end

        new_parent_id = changes['parent_id'][1]
        if new_parent_id
          new_parent = FacetItem.find(new_parent_id)
          facet_item_owners.each do |facet_item_owner|
            facet_item_owner.owner.facet_items << new_parent
          end
        end
      end
    end

    def facet_supports_type_of_owner?(owner)
      type = owner.class.to_s.split('::').last
      facet.owner_types.where(owner_type: type).exists?
    end

  end
end
