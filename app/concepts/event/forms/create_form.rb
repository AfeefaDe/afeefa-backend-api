class Event < ApplicationRecord
  module Forms
    class CreateForm < Reform::Form

      property :title
      property :description
      property :active
      property :public_speaker
      property :support_wanted
      property :parent_id
      property :date
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

    end
  end
end