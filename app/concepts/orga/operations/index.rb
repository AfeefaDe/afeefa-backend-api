class Orga < ApplicationRecord
  module Operations
    class Index < Trailblazer::Operation
      include Collection

      def model!(params)
        if params[:page]
          orgas = Orga.page(params[:page][:number]).per(params[:page][:size])
        else
          orgas = Orga.all
        end
      end
    end
  end
end
