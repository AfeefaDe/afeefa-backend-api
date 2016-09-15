class Event < ApplicationRecord
  module Operations
    class Show < Trailblazer::Operation

      include Model
      model Event, :find
    end
  end
end