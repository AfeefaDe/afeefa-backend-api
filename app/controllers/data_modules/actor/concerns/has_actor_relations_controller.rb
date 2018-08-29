module DataModules::Actor::Concerns::HasActorRelationsController
  extend ActiveSupport::Concern

  def get_project_initiators
    find_actor
    render status: :ok, json: @actor.project_initiators_to_hash
  end

  def link_project_initiators
    find_actor

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        @actor.project_initiators.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(actor_id, nil, DataModules::Actor::ActorRelation::PROJECT)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def get_projects
    find_actor
    render status: :ok, json: @actor.projects_to_hash
  end

  def link_projects
    find_actor

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        @actor.projects.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(nil, actor_id, DataModules::Actor::ActorRelation::PROJECT)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def get_networks
    find_actor
    render status: :ok, json: @actor.networks_to_hash
  end

  def link_networks
    find_actor

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        @actor.networks.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(actor_id, nil, DataModules::Actor::ActorRelation::NETWORK)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def get_network_members
    find_actor
    render status: :ok, json: @actor.network_members_to_hash
  end

  def link_network_members
    find_actor

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        @actor.network_members.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(nil, actor_id, DataModules::Actor::ActorRelation::NETWORK)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def get_partners
    find_actor
    render status: :ok, json: @actor.partners_to_hash
  end

  def link_partners
    find_actor

    begin
      ActiveRecord::Base.transaction do # fail if one fails
        @actor.partners_i_have_associated.destroy_all
        @actor.partners_that_associated_me.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          add_association(nil, actor_id, DataModules::Actor::ActorRelation::PARTNER)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  private

  def find_actor
    @actor = Orga.find(params[:id])
  end

  def get_association(left_id, right_id, type)
    DataModules::Actor::ActorRelation.find_by(
      associating_actor_id: left_id,
      associated_actor_id: right_id,
      type: type
    )
  end

  def add_association(left_id, right_id, type)
    if get_association(left_id, right_id, type)
      raise 'Association already exists'
      return
    end

    left = left_id ? Orga.find(left_id) : @actor
    right = right_id ? Orga.find(right_id) : @actor

    unless left.area == right.area
      raise 'Actor is in wrong area'
    end

    DataModules::Actor::ActorRelation.create(
      associating_actor: left,
      associated_actor: right,
      type: type
    )
  end
end
