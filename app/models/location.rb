class Location < ApplicationRecord
  # ATTRIBUTES AND ASSOCIATIONS
  belongs_to :locatable, polymorphic: true
end
