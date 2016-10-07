class Orga < ApplicationRecord
  module Operations
    class CreateSubOrga < Trailblazer::Operation

      include Model
      model Orga, :create

      contract Orga::Forms::CreateSubOrgaForm do
        validates :parent_id, presence: true
      end

      def process(params)
        validate(params[:data][:attributes]) do |new_sub_orga_form|
          current_user = params[:current_user]
          parent_orga = Orga.find(params[:data][:attributes][:parent_id])
          params
          current_user
          current_user.can! :write_orga_structure, parent_orga, 'You are not authorized to modify the structure of this organization!'
          new_sub_orga_form.save
          Role.create!(user: current_user, orga: new_sub_orga_form.model, title: Role::ORGA_ADMIN)
          parent_orga.sub_orgas << new_sub_orga_form.model
        end
      end
    end
  end
end
