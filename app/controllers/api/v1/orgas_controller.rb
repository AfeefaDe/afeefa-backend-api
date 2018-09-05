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
      orgas = Orga.
        all_for_ids(params[:ids].split(/,/)).
        map do |orga|
          orga.to_hash(attributes: Orga.default_attributes_for_json, relationships: Orga.default_relations_for_json)
        end
      else
        orgas = Orga.includes(Orga.lazy_includes).
        by_area(area).
        map do |orga|
          orga.serialize_lazy
        end
    end

    render status: :ok, json: { data: orgas }
  end

  def get_offers
    orga = Orga.find(params[:id])
    render status: :ok, json: orga.offers_to_hash
  end
end
