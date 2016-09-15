class Event < ApplicationRecord
  class Show < Trailblazer::Operation

    include Model
    model Event, :find
  end
end