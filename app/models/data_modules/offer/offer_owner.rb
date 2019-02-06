module DataModules::Offer
  class OfferOwner < ApplicationRecord
    belongs_to :offer
    belongs_to :actor, class_name: Orga # TODO: change to DataModules::Actor::Actor

    include FapiCacheable

    def fapi_cacheable_on_save
      area = Area[actor.area]
      FapiCacheJob.new.update_all_entries_for_area(area)
    end

    def fapi_cacheable_on_destroy
      fapi_cacheable_on_save
    end
  end
end
