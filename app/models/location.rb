class Location < ApplicationRecord
  belongs_to :locatable, polymorphic: true
end
