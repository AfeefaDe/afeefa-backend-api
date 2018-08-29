module DataModules::FeNavigation::Concerns::HasFeNavigationItems
  extend ActiveSupport::Concern

  included do
    has_many :navigation_item_owners,
      class_name: DataModules::FeNavigation::FeNavigationItemOwner, as: :owner, dependent: :destroy
    has_many :navigation_items, through: :navigation_item_owners

    def navigation_items_to_hash
      navigation_items.map { |item| item.to_hash(attributes: nil, relationships: nil) }
    end

  end

end
