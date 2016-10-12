class Orga < ApplicationRecord
  module Operations
    class UpdateData < Trailblazer::Operation
      include Model
      model Orga, :find

      contract Orga::Forms::UpdateForm

      def process(params)
        validate(params[:data][:attributes]) do |orga_form|
          current_user = params[:current_user]
          current_user.can! :write_orga_data, orga_form.model, 'You are not authorized to modify the data of this organization!'
          orga_form.save
        end
      end
    end

    class UpdateStructure < UpdateData
      def process(params)
        validate(params[:data][:attributes]) do |orga_form|
          current_user = params[:current_user]
          current_user.can! :write_orga_structure, orga_form.model, 'You are not authorized to modify the structure of this organization!'
          orga_form.save
        end
      end
    end

    class UpdateAll < UpdateData
      def process(params)
        validate(params[:data][:attributes]) do |orga_form|
          current_user = params[:current_user]
          current_user.can! :write_orga_data, orga_form.model, 'You are not authorized to modify the data of this organization!'
          current_user.can! :write_orga_structure, orga_form.model, 'You are not authorized to modify the structure of this organization!'
          orga_form.save
        end
      end
    end
  end
end
