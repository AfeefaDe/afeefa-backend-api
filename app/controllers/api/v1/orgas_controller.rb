class Api::V1::OrgasController < Api::V1::EntriesBaseController
  include DataModules::Actor::Concerns::HasActorRelationsController

  def show
    orga = Orga.find(params[:id])
    # put more details into the orga.project_intitators list @see orga#project_initiators_to_hash
    initiators_hash = orga.project_initiators.map { |i| i.to_hash }
    orga_hash = orga.as_json
    orga_hash[:relationships][:project_initiators] = { data: initiators_hash }
    render status: :ok, json: { data: orga_hash }
  end

  def index
    area = current_api_v1_user.area

    if params[:ids]
      orgas = Orga.all_for_ids(params[:ids].split(/,/))
    else
      orgas = Orga.
        includes([:facet_items, :navigation_items]).
        by_area(area).
        map do |orga|
        {
          id: orga.id,
          type: 'orgas',
          attributes: {
            title: orga.title,
            created_at: orga.created_at,
            active: orga.active
          },
          relationships: {
            facet_items: orga.facet_items_to_hash,
            navigation_items: orga.navigation_items_to_hash,
          }
        }
      end
    end

    render status: :ok, json: orgas.as_json
  end

  def get_offers
    orga = Orga.find(params[:id])
    render status: :ok, json: orga.offers_to_hash
  end

  def do_includes!(objects)
    objects.includes(Orga.default_includes)
  end
end
