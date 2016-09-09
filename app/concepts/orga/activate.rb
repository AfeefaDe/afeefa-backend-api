class Orga < ApplicationRecord
  class Activate < Trailblazer::Operation

    include Model
    model Orga, :find

    contract do
      property :active
      # , validates: { within: [true, false] }
    end

    def process(params)
      validate(params[:data][:attributes]) do
        user = params[:user]
        user.can! :write_orga_data, model, 'You are not authorized to modify this organization!'
        contract.save
      end
    end

  end
end
