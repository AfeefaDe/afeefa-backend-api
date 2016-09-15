class User < ApplicationRecord
  class Show < Trailblazer::Operation

    include Model
    model User, :find
  end
end