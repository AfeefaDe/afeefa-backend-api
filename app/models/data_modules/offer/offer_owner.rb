module DataModules::Offer
  class OfferOwner < ApplicationRecord
    belongs_to :offer
    belongs_to :actor, class_name: Orga # TODO: change to DataModules::Actor::Actor
  end
end
