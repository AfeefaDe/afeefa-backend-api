class Api::V1::OrgasController < Api::V1::EntriesBaseController

  include HasActorRelations

  def show
    orga = Orga.find(params[:id])
    # put more details into the orga.project_intitators list @see orga#project_initiators_to_hash
    initiators_hash = orga.project_initiators.map { |i| i.to_hash }
    orga_hash = orga.as_json
    orga_hash[:relationships][:project_initiators] = { data: initiators_hash }
    render status: :ok, json: { data: orga_hash }
  end

  def get_offers
    orga = Orga.find(params[:id])
    render status: :ok, json: orga.offers_to_hash
  end

  def do_includes!(objects)
    objects.includes(Orga.default_includes)
  end

end
