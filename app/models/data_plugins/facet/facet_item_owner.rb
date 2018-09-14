module DataPlugins::Facet
  class FacetItemOwner < ApplicationRecord

    include FapiCacheable

    belongs_to :facet_item
    belongs_to :owner, polymorphic: true

    def fapi_cacheable_on_save
      FapiCacheJob.new.update_entry(owner)
    end

    def fapi_cacheable_on_destroy
      fapi_cacheable_on_save
    end

  end
end
