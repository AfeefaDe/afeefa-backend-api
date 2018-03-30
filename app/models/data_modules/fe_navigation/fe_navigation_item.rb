module DataModules::FeNavigation
  class FeNavigationItem < ApplicationRecord
    include Jsonable
    include DataPlugins::Facet::Concerns::ActsAsFacetItem

    # ASSOCIATIONS
    belongs_to :navigation, class_name: DataModules::FeNavigation::FeNavigation
    belongs_to :parent, class_name: FeNavigationItem
    has_many :sub_items, class_name: FeNavigationItem, foreign_key: :parent_id, dependent: :destroy

    has_many :navigation_item_owners,
      class_name: FeNavigationItemOwner, foreign_key: 'navigation_item_id', dependent: :destroy

    has_many :events, through: :navigation_item_owners, source: :owner, source_type: 'Event'
    has_many :orgas, through: :navigation_item_owners, source: :owner, source_type: 'Orga'
    has_many :offers, through: :navigation_item_owners, source: :owner, source_type: 'DataModules::Offer::Offer'
    has_many :facet_items, through: :navigation_item_owners, source: :owner, source_type: 'DataPlugins::Facet::FacetItem'

    def owners
      (events + orgas + offers + facet_items.map { |fi| fi.owners }.flatten).uniq
    end

    def count_owners
      sql = <<-eos
        select count(*)
        from fe_navigation_item_owners
        where navigation_item_id = #{id}
        and owner_type != 'DataPlugins::Facet::FacetItem'
      eos
      count_owners = ActiveRecord::Base.connection.select_value(sql)

      sql = <<-eos
        select count(*)
        from facet_item_owners fo
        inner join fe_navigation_item_owners no
        on fo.facet_item_id = no.owner_id
        where no.navigation_item_id = #{id}
        and no.owner_type = 'DataPlugins::Facet::FacetItem'
      eos
      count_facet_owners = ActiveRecord::Base.connection.select_value(sql)

      count_owners + count_facet_owners
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
        %i(title color parent_id count_owners).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(sub_items facet_items).freeze
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

      if !supports_type_of_owner?(owner)
        return false
      end

      FeNavigationItemOwner.create(
        owner: owner,
        navigation_item_id: id
      )

      # link parent too
      if parent
        FeNavigationItemOwner.find_or_create_by(
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

    def validate_navigation_and_parent
      if persisted? && changes.key?('navigation_id')
        return errors.add(:navigation_id, 'Navigation kann nicht geändert werden.')
      end

      unless FeNavigation.exists?(navigation_id)
        return errors.add(:navigation_id, 'Navigation existiert nicht.')
      end

      validate_parent_relation

      # cannot set parent with different navigation_id
      parent = self.class.find_by_id(parent_id)
      if parent && parent.navigation_id != navigation_id
        return errors.add(:parent_id, 'Ein übergeordneter Menüpunkt muss zur selben Navigation gehören.')
      end
    end

    def supports_type_of_owner?(owner)
      allowed_owners = ['Orga', 'Event', 'Offer', 'FacetItem']
      type = owner.class.to_s.split('::').last
      allowed_owners.include?(type)
    end

    # ActsAsFacetItem

    def item_owners(item = nil)
      item = item || self
      item.navigation_item_owners
    end

    def items_of_owners(owner)
      owner.navigation_items
    end

    def message_parent_nonexisting
      'Übergeordneter Menüpunkt existiert nicht.'
    end

    def message_item_sub_of_sub
      'Ein Menüpunkt kann nicht Unterpunkt eines Unterpunktes sein.'
    end

    def message_sub_of_itself
      'Ein Menüpunkt kann nicht sein Unterpunkt sein.'
    end

    def message_sub_cannot_be_nested
      'Ein Menüpunkt mit Unterpunkten kann nicht verschachtelt werden.'
    end

  end
end
