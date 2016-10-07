class Orga < ApplicationRecord
  module Operations
    class ListUsers < Trailblazer::Operation

      include Collection

      def model!(params)
        current_user = params[:current_user]
        orga = Orga.find(params[:id])
        current_user.can! :read_orga, orga, 'You are not authorized to read the data of this organization!'
        orga.users
      end

    end
  end
end
