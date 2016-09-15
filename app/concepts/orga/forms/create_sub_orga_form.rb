class Orga < ApplicationRecord
  module Forms
    class CreateSubOrgaForm < Reform::Form

      property :title
      property :description
      property :active
      property :parent_id
      property :category_ids

      collection :contact_infos do
        property :type
        property :content
      end

      collection :locations do
        property :lat
        property :lon
        property :street
        property :number
        property :addition
        property :zip
        property :city
        property :district
        property :state
        property :country
        property :displayed
      end

      validates :title, presence: true, length: { minimum: 5 }
      # TODO: maybe refactor and write own UniquenessValidator
      validates_uniqueness_of :title

    end
  end
end
