class Todo < ApplicationRecord
  module Operations
    class Index < Trailblazer::Operation

      def model!(params)
        orgas = Orga.where(state: Thing::TODO_STATES)
        events = Event.where(state: Thing::TODO_STATES)
        {
            data: {
                relationships: {
                    orgas: {
                        data: orgas
                    },
                    events: {
                        data: events
                    }
                }
            }
        }
      end
    end
  end
end
