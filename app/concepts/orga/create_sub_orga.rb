class Orga < ApplicationRecord
  class CreateSubOrga < Trailblazer::Operation

    include Model
    model Orga, :create

    contract do
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
      #todo: maybe refactore and write own UniquenessValidator
      validates_uniqueness_of :title

    end

    def process(params)
      validate(params[:data][:attributes]) do |new_sub_orga|
        user = params[:user]
        parent_orga = Orga.find(params[:id])
        user.can! :write_orga_structure, parent_orga, 'You are not authorized to modify the structure of this organization!'
        new_sub_orga.save
        Role.create!(user: user, orga: new_sub_orga.model, title: Role::ORGA_ADMIN)
        parent_orga.sub_orgas << new_sub_orga.model
      end
    end

  end
end
