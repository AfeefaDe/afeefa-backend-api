class Orga < ApplicationRecord
  module Operations
    class Index < Trailblazer::Operation
      include Collection

      def model!(params)
        if params[:page]
          Orga.page(params[:page][:number]).per(params[:page][:size])
        else
          Orga.all
        end
      end
    end
  end
end
