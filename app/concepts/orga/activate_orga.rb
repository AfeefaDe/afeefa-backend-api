class Orga < ApplicationRecord
  class ActivateOrga < Trailblazer::Operation

    include Model
    model Orga

    contract do
      property :active
      # , validates: { within: [true, false] }
    end

    def process(params)
      validate(params[:data][:attributes]) do |orga|
        user = params[:user]
        user.can! :write_orga_data, orga, 'You are not authorized to modify this organization!'
        orga.save
      end
    end

  end
end
