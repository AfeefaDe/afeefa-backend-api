module DataModules::FENavigation
  class FENavigationItemOwner < ApplicationRecord

    belongs_to :navigation_item, class_name: DataModules::FENavigation::FENavigationItem
    belongs_to :owner, polymorphic: true

  end
end
