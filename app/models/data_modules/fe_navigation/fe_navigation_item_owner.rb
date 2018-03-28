module DataModules::FeNavigation
  class FeNavigationItemOwner < ApplicationRecord

    belongs_to :navigation_item, class_name: DataModules::FeNavigation::FeNavigationItem
    belongs_to :owner, polymorphic: true

  end
end
