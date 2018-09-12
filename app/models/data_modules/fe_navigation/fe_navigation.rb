module DataModules::FeNavigation
  class FeNavigation < ApplicationRecord
    include Jsonable

    # ASSOCIATIONS
    has_many :navigation_items,
      -> { ordered },
      class_name: DataModules::FeNavigation::FeNavigationItem,
      foreign_key: 'navigation_id',
      dependent: :destroy

    scope :by_area, -> (area) { where(area: area) }

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i().freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(navigation_items).freeze
      end

    end

    def navigation_items_to_hash(relationships: nil)
      items = navigation_items.select { |item| item.parent_id == nil }
      items.map { |item| item.to_hash(attributes: item.class.default_attributes_for_json) }
    end

    def order_navigation_items!(ids)
      ActiveRecord::Base.transaction do # fail if one fails
        # reset order for not given items
        navigation_items.where.not(id: ids).each do |item|
          item.update_attribute(:order, 0)
        end
        # set new order for given items
        ids.each_with_index do |id, index|
          navigation_items.find(id).update_attribute(:order, index + 1)
        end
      end
    end
  end
end
