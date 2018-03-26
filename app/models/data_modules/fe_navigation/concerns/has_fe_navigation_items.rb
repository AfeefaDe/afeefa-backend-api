module DataModules::FENavigation::Concerns::HasFENavigationItems
  extend ActiveSupport::Concern

  included do
    has_many :navigation_item_owners,
      class_name: DataModules::FENavigation::FENavigationItemOwner, as: :owner
    has_many :navigation_items, through: :navigation_item_owners
  end

end
