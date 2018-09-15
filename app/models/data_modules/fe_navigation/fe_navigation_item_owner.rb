module DataModules::FeNavigation
  class FeNavigationItemOwner < ApplicationRecord

    include FapiCacheable

    belongs_to :navigation_item, class_name: DataModules::FeNavigation::FeNavigationItem
    belongs_to :owner, polymorphic: true

    def fapi_cacheable_on_save
      FapiCacheJob.new.update_entry(owner)
    end

    def fapi_cacheable_on_destroy
      fapi_cacheable_on_save
    end

  end
end
