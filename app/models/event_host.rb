class EventHost < ApplicationRecord
  belongs_to :event
  belongs_to :actor, class_name: Orga # TODO: change to DataModules::Actor::Actor
end
