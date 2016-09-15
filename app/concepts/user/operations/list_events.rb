class User < ApplicationRecord
  module Operations
    class ListEvents < Trailblazer::Operation
      include Collection

      def model!(params)
        current_user = params[:current_user]
        if current_user.id.== params[:id].to_i
          events = current_user.events
        else
          raise CanCan::AccessDenied
        end
      end
    end
  end
end