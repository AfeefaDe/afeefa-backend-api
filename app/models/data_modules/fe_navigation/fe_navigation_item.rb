module DataModules::FENavigation
  class FENavigationItem < ApplicationRecord
    include Jsonable

    # ASSOCIATIONS
    belongs_to :navigation, class_name: DataModules::FENavigation::FENavigation
    belongs_to :parent, class_name: FENavigationItem
    has_many :sub_items, class_name: FENavigationItem, foreign_key: :parent_id, dependent: :destroy

    has_many :navigation_item_owners,
      class_name: FENavigationItemOwner, foreign_key: 'navigation_item_id', dependent: :destroy
    has_many :events, -> { by_area(Current.user.area) }, through: :navigation_item_owners,
      source: :owner, source_type: 'Event'
    has_many :orgas, -> { by_area(Current.user.area) }, through: :navigation_item_owners,
      source: :owner, source_type: 'Orga'
    has_many :offers, -> { by_area(Current.user.area) }, through: :navigation_item_owners,
      source: :owner, source_type: 'DataModules::Offer::Offer', class_name: DataModules::Offer::Offer

    def owners
      events + orgas + offers
    end

    # VALIDATIONS
    validates :title, length: { maximum: 255 }
    validates :color, length: { maximum: 255 }

    validates :navigation_id, presence: true
    validates :parent_id, presence: true, allow_nil: true
    validate :validate_navigation_and_parent

    # SAVE HOOKS
    after_save :move_owners_to_new_parent

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
        %i(sub_items).freeze
      end

      def navigation_item_params(params)
        params.permit(:title, :color, :navigation_id, :parent_id)
      end

      def save_navigation_item(params)
        navigation_item = find_or_initialize_by(id: params[:id])
        params = navigation_item_params(params)
        navigation_item.assign_attributes(params)
        navigation_item.save!
        navigation_item
      end
    end

    def link_owner(owner)
      if navigation_item_owners.where(owner: owner).exists?
        return false
      end

      FENavigationItemOwner.create(
        owner: owner,
        navigation_item_id: id
      )

      # link parent too
      if parent
        FENavigationItemOwner.find_or_create_by(
          owner: owner,
          navigation_item_id: parent.id
        )
      end

      true
    end

    def unlink_owner(owner)
      navigation_item_owner = navigation_item_owners.where(owner: owner).first

      return false unless navigation_item_owner

      navigation_item_owners.delete(navigation_item_owner)

      # unlink subitems too
      if (sub_items.count)
        sub_items.each do |sub_item|
          navigation_item_owner = sub_item.navigation_item_owners.where(owner: owner).first
          if navigation_item_owner
            sub_item.navigation_item_owners.delete(navigation_item_owner)
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

    def move_owners_to_new_parent
      if changes.key?('parent_id')
        old_parent_id = changes['parent_id'][0]
        if old_parent_id
          old_parent = FENavigationItem.find(old_parent_id)
          navigation_item_owners.each do |navigation_item_owner|
            # remove only from parent if no other sub association to that parent exists
            sub_navigation_items_with_parent = 0
            navigation_item_owner.owner.navigation_items.each do |navigation_item|
              if navigation_item.parent_id == old_parent_id
                sub_navigation_items_with_parent += 1
              end
            end
            if sub_navigation_items_with_parent == 0
              navigation_item_owner.owner.navigation_items.delete(old_parent)
            end
          end
        end

        new_parent_id = changes['parent_id'][1]
        if new_parent_id
          new_parent = FENavigationItem.find(new_parent_id)
          navigation_item_owners.each do |navigation_item_owner|
            navigation_item_owner.owner.navigation_items << new_parent
          end
        end
      end
    end

    def validate_navigation_and_parent
      if persisted? && changes.key?('navigation_id')
        return errors.add(:navigation_id, 'Navigation kann nicht geändert werden.')
      end

      unless FENavigation.exists?(navigation_id)
        return errors.add(:navigation_id, 'Navigation existiert nicht.')
      end

      if parent_id
        unless FENavigationItem.exists?(parent_id)
          return errors.add(:parent_id, 'Übergeordneter Menüpunkt existiert nicht.')
        end

        # cannot set parent to self
        if parent_id == id
          return errors.add(:parent_id, 'Ein Menüpunkt kann nicht sein Unterpunkt sein.')
        end

        # cannot set parent if sub_items present
        if sub_items.any?
          return errors.add(:parent_id, 'Ein Menüpunkt mit Unterpunkten kann nicht verschachtelt werden.')
        end

        parent = FENavigationItem.find_by_id(parent_id)

        # cannot set parent to sub_item
        if parent.parent_id
          return errors.add(:parent_id, 'Ein Menüpunkt kann nicht Unterpunkt eines Unterpunktes sein.')
        end

        # cannot set parent with different navigation_id
        if parent.navigation_id != navigation_id
          return errors.add(:parent_id, 'Ein übergeordneter Menüpunkt muss zur selben Navigation gehören.')
        end
      end
    end

  end

end
