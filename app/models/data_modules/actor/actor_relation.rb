module DataModules::Actor
  class ActorRelation < ApplicationRecord

    include FapiCacheable

    # disable rails single table inheritance
    self.inheritance_column = :_type_disabled

    PROJECT = :has_project
    NETWORK = :is_network_of
    PARTNER = :is_partner_of
    ASSOCIATION_TYPES = [PROJECT, NETWORK, PARTNER].freeze

    # ASSOCIATIONS
    belongs_to :associating_actor, class_name: Orga # TODO: change to DataModules::Actor::Actor
    belongs_to :associated_actor, class_name: Orga # TODO: change to DataModules::Actor::Actor

    scope :project, -> { where(type: PROJECT) }
    scope :network, -> { where(type: NETWORK) }
    scope :partner, -> { where(type: PARTNER) }

    def fapi_cacheable_on_save
      area = Area.find_by(title: associating_actor.area)
      FapiCacheJob.new.update_all_entries_for_area(area)
    end

    def fapi_cacheable_on_destroy
      fapi_cacheable_on_save
    end

  end
end
