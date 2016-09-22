class Orga < ApplicationRecord
  module Operations
    class Delete < Trailblazer::Operation

      include Model
      model Orga, :find

      def process(params)
        current_user = params[:current_user]
        orga = Orga.find(params[:id])
        current_user.can! :write_orga_structure, orga, 'You are not authorized to delete an organization!'
        parent_orga = Orga.find(orga.parent_id)
        sub_orgas = orga.sub_orgas

        # move sub_orgas to parent_orga
        move_sub_orgas_to_new_parent(parent_orga, sub_orgas)

        # todo: handle case: What if a user only was in this orga?

        orga.reload
        orga.destroy!
      end

      def move_sub_orgas_to_new_parent(parent_orga, sub_orgas)
        sub_orgas.each do |sub_orga|
          sub_orga.parent_orga = parent_orga
          sub_orga.save
        end
      end

    end
  end
end