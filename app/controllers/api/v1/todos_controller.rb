class Api::V1::TodosController < Api::V1::BaseController
  def index
    orgas = Orga.where(state: Thing::TODO_STATES)
    events = Event.where(state: Thing::TODO_STATES)
    render json: {
        data: {
            relationships: {
                orgas: {
                    data: ActiveModelSerializers::SerializableResource.new(orgas).to_json
                },
                events: {
                    data: ActiveModelSerializers::SerializableResource.new(events).to_json
                }
            }
        }
    }
  end
end
