class User < ApplicationRecord
  module Operations
    class ListOrgas < Trailblazer::Operation
      include Collection

      def model!(params)
        current_user = params[:current_user]
        if current_user.id.== params[:id].to_i
          orgas = current_user.orgas
        else
          raise CanCan::AccessDenied
        end
      end
    end
  end
end