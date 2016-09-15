class Orga < ApplicationRecord
  module Operations
    class Update < CreateSubOrga
      model Orga, :find

      contract Orga::Forms::UpdateForm

      def process(params)
        validate(params[:data][:attributes]) do |orga_form|
          user = params[:user]
          user.can! :write_orga_data, orga_form.model, 'You are not authorized to modify the data of this organization!'
          orga_form.save
        end
      end

    end
  end
end
