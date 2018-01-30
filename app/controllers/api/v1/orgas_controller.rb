class Api::V1::OrgasController < Api::V1::EntriesBaseController

  def add_project
    add_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::PROJECT)
  end

  def remove_project
    remove_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::PROJECT)
  end

  def add_network_member
    add_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::NETWORK)
  end

  def remove_network_member
    remove_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::NETWORK)
  end

  def add_partner
    add_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::PARTNER)
  end

  def remove_partner
    remove_association(params[:id], params[:item_id], DataModules::Actor::ActorRelation::PARTNER)
  end

  def do_includes!(objects)
    objects = super(objects).
      includes(:events).
      includes(:resource_items).
      includes(:project_initiators).
      includes(:projects).
      includes(:network_members)
    objects
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
