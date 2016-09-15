class User < ApplicationRecord
  module Operations
    class Show < Trailblazer::Operation

      include Model
      model User, :find

    end
  end
end