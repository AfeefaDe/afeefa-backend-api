class Orga < ApplicationRecord
  module Operations
    class Show < Trailblazer::Operation
      include Model
      model Orga, :find
    end
  end
end
