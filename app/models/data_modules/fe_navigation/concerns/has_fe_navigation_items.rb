module DataModules::FeNavigation::Concerns::HasFeNavigationItems
  extend ActiveSupport::Concern

  included do
    has_many :navigation_item_owners,
      class_name: DataModules::FeNavigation::FeNavigationItemOwner, as: :owner, dependent: :destroy
    has_many :navigation_items, through: :navigation_item_owners
  end

end
