class OwnerThingRelation < ApplicationRecord
  belongs_to :ownable, polymorphic: true
  belongs_to :thingable, polymorphic: true
end
