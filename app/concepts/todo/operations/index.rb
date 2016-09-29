class Todo < ApplicationRecord
  module Operations
    class Index < Trailblazer::Operation

      def model!(params)
        orgas = Orga.where(state: Thing::TODO_STATES)
        events = Event.where(state: Thing::TODO_STATES)
        {orgas: orgas, events: events}
      end
    end
  end
end
