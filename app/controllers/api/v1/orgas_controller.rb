class Api::V1::OrgasController < Api::V1::EntriesBaseController

  def get_actor_relations
    orga = Orga.find(params[:id])
    json = {}
    %i(projects project_initiators networks network_members partners).each do |relation|
      json[relation] = orga.send("#{relation}_to_hash")
    end
    render status: :ok, json: json
  end

  def link_project_initiators
    orga = Orga.find(params[:id])

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        orga.project_initiators.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(actor_id, orga.id, DataModules::Actor::ActorRelation::PROJECT)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def add_project
    add_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::PROJECT)
  end

  def remove_project
    remove_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::PROJECT)
  end

  def link_projects
    orga = Orga.find(params[:id])

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        orga.projects.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(orga.id, actor_id, DataModules::Actor::ActorRelation::PROJECT)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def link_networks
    orga = Orga.find(params[:id])

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        orga.networks.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(actor_id, orga.id, DataModules::Actor::ActorRelation::NETWORK)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def add_network_member
    add_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::NETWORK)
  end

  def remove_network_member
    remove_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::NETWORK)
  end

  def link_network_members
    orga = Orga.find(params[:id])

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        orga.network_members.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(orga.id, actor_id, DataModules::Actor::ActorRelation::NETWORK)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def add_partner
    add_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::PARTNER)
  end

  def remove_partner
    remove_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::PARTNER)
  end

  def link_partners
    orga = Orga.find(params[:id])

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        orga.partners_i_have_associated.destroy_all
        orga.partners_that_associated_me.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(orga.id, actor_id, DataModules::Actor::ActorRelation::PARTNER)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def do_includes!(objects)
    objects.includes(Orga.default_includes)
  end

  private

  def get_association(left_id, right_id, type)
    DataModules::Actor::ActorRelation.find_by(
      associating_actor_id: left_id,
      associated_actor_id: right_id,
      type: type
    )
  end

  def add_association(left_id, right_id, type)
    if get_association(left_id, right_id, type)
      head 400
      return
    end

    result =
      DataModules::Actor::ActorRelation.create(
        associating_actor_id: left_id,
        associated_actor_id: right_id,
        type: type
      )
    if result
      head 201
    else
      head 500
    end
  end

  def remove_association(left_id, right_id, type)
    association = get_association(left_id, right_id, type)
    if association
      if association.destroy
        head 200
      else
        head 500
      end
    else
      head 404
    end
  end

end
