class Api::V1::TodosController < Api::V1::BaseController
  def index
    orgas = Orga.where(state: Thing::TODO_STATES).map { |o| JSONAPI::ResourceSerializer.new(Api::V1::OrgaResource).serialize_to_hash(Api::V1::OrgaResource.new(o, nil)) }
    events = Event.where(state: Thing::TODO_STATES).map { |o| JSONAPI::ResourceSerializer.new(Api::V1::EventResource).serialize_to_hash(Api::V1::EventResource.new(o, nil)) }

    render json: {
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
